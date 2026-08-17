import os

import joblib
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from xgboost import XGBClassifier

from incidents.models import AISeverityPrediction

from .credibility import REPORT_TYPE_IDS

MODEL_DIR = os.path.join(os.path.dirname(__file__), 'saved_models')
MODEL_PATH = os.path.join(MODEL_DIR, 'xgboost_model.pkl')

FEATURE_COLUMNS = [
    'incident_type_id', 'victims_count', 'cluster_size', 'credibility_score',
    'hour_of_day', 'is_night',
]

SEVERITY_LEVEL_NAMES = {1: 'low', 2: 'moderate', 3: 'high', 4: 'critical'}


def generate_severity_dataset(n_rows=5000, random_state=42):
    rng = np.random.default_rng(random_state)

    incident_type_id = rng.integers(1, 8, n_rows)
    victims_count = rng.integers(0, 51, n_rows)
    cluster_size = rng.integers(1, 51, n_rows)
    credibility_score = rng.uniform(0, 100, n_rows)
    hour_of_day = rng.integers(0, 24, n_rows)
    citizen_severity = rng.integers(1, 5, n_rows)
    is_night = ((hour_of_day >= 20) | (hour_of_day < 6)).astype(int)

    base = citizen_severity.astype(int).copy()
    base = np.where(victims_count > 20, np.minimum(4, base + 1), base)
    base = np.where(cluster_size > 15, np.minimum(4, base + 1), base)
    base = np.where(credibility_score < 40, np.maximum(1, base - 1), base)
    night_relevant_type = np.isin(incident_type_id, [1, 2])
    base = np.where((is_night == 1) & night_relevant_type, np.minimum(4, base + 1), base)

    label = np.clip(base, 1, 4)

    return pd.DataFrame({
        'incident_type_id': incident_type_id,
        'victims_count': victims_count,
        'cluster_size': cluster_size,
        'credibility_score': credibility_score,
        'hour_of_day': hour_of_day,
        'citizen_severity': citizen_severity,
        'is_night': is_night,
        'label': label,
    })


def train_severity_model():
    df = generate_severity_dataset()
    X = df[FEATURE_COLUMNS]
    y = df['label'] - 1  # XGBoost needs zero-indexed labels.

    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    model = XGBClassifier(
        n_estimators=200,
        max_depth=4,
        learning_rate=0.1,
        use_label_encoder=False,
        eval_metric='mlogloss',
        random_state=42,
    )
    model.fit(X_train, y_train)

    accuracy = model.score(X_test, y_test)
    print(f'Severity model accuracy: {accuracy:.4f}')

    os.makedirs(MODEL_DIR, exist_ok=True)
    joblib.dump(model, MODEL_PATH)
    return model


def predict_severity(report, cluster, credibility_score):
    model = joblib.load(MODEL_PATH)

    hour_of_day = report.created_at.hour
    is_night = 1 if (hour_of_day >= 20 or hour_of_day < 6) else 0

    features = pd.DataFrame([{
        'incident_type_id': REPORT_TYPE_IDS.get(report.report_type, 0),
        'victims_count': int(report.victims_count or 0),
        'cluster_size': int(cluster.report_count),
        'credibility_score': float(credibility_score or 0),
        'hour_of_day': hour_of_day,
        'is_night': is_night,
    }])[FEATURE_COLUMNS]

    probabilities = model.predict_proba(features)[0]
    predicted_index = int(np.argmax(probabilities))
    predicted_level = predicted_index + 1  # Add 1 back since training subtracted it.

    return AISeverityPrediction.objects.create(
        incident=cluster,
        predicted_level=SEVERITY_LEVEL_NAMES[predicted_level],
        probability_low=float(probabilities[0]),
        probability_medium=float(probabilities[1]),
        probability_high=float(probabilities[2]),
        probability_critical=float(probabilities[3]),
        confidence=float(probabilities[predicted_index]),
        model_version='xgboost_v1',
    )
