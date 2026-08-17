import os

import joblib
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split

from incidents.models import AICredibilityScore

MODEL_DIR = os.path.join(os.path.dirname(__file__), 'saved_models')
MODEL_PATH = os.path.join(MODEL_DIR, 'random_forest.pkl')

FEATURE_COLUMNS = [
    'cluster_size', 'user_report_count', 'user_false_rate', 'is_witness_mode',
    'incident_type_id', 'submission_method', 'hour_of_day',
]

REPORT_TYPE_IDS = {
    'accident': 1, 'fire': 2, 'medical': 3, 'flood': 4,
    'security': 5, 'hazmat': 6, 'weather': 7, 'sos': 1, 'other': 1,
}

SUBMISSION_METHOD_IDS = {'form': 0, 'sos': 1, 'voice': 2, 'witness': 3}


def generate_simulated_dataset(n_rows=3000, random_state=42):
    rng = np.random.default_rng(random_state)

    cluster_size = rng.integers(1, 51, n_rows)
    user_report_count = rng.integers(1, 21, n_rows)
    user_false_rate = rng.uniform(0.0, 0.5, n_rows)
    is_witness_mode = rng.integers(0, 2, n_rows)
    incident_type_id = rng.integers(1, 8, n_rows)
    submission_method = rng.integers(0, 4, n_rows)
    hour_of_day = rng.integers(0, 24, n_rows)

    score = np.full(n_rows, 50.0)
    score += np.where(cluster_size > 5, 30, 0)
    score += np.where(user_false_rate < 0.1, 10, 0)
    score += np.where(user_false_rate > 0.3, -20, 0)
    score += np.where(is_witness_mode == 1, 10, 0)
    score += np.where(submission_method == 1, -15, 0)
    score += np.where(submission_method == 0, 5, 0)

    label = (score >= 50).astype(int)

    return pd.DataFrame({
        'cluster_size': cluster_size,
        'user_report_count': user_report_count,
        'user_false_rate': user_false_rate,
        'is_witness_mode': is_witness_mode,
        'incident_type_id': incident_type_id,
        'submission_method': submission_method,
        'hour_of_day': hour_of_day,
        'label': label,
    })


def train_credibility_model():
    df = generate_simulated_dataset()
    X = df[FEATURE_COLUMNS]
    y = df['label']

    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    model = RandomForestClassifier(n_estimators=100, random_state=42)
    model.fit(X_train, y_train)

    accuracy = model.score(X_test, y_test)
    print(f'Credibility model accuracy: {accuracy:.4f}')

    os.makedirs(MODEL_DIR, exist_ok=True)
    joblib.dump(model, MODEL_PATH)
    return model


def _band_for_score(score_percent):
    if score_percent >= 70:
        return 'green'
    if score_percent >= 40:
        return 'yellow'
    return 'red'


def score_credibility(report, cluster):
    model = joblib.load(MODEL_PATH)

    reporter = report.reporter
    if reporter:
        user_reports = reporter.reports.all()
        total = user_reports.count()
        rejected = user_reports.filter(status='rejected').count()
        user_report_count = total
        user_false_rate = (rejected / total) if total else 0.0
    else:
        user_report_count = 0
        user_false_rate = 0.0

    feature_values = {
        'cluster_size': int(cluster.report_count),
        'user_report_count': int(user_report_count),
        'user_false_rate': float(user_false_rate),
        'is_witness_mode': 1 if report.submission_method == 'witness' else 0,
        'incident_type_id': REPORT_TYPE_IDS.get(report.report_type, 0),
        'submission_method': SUBMISSION_METHOD_IDS.get(report.submission_method, 0),
        'hour_of_day': report.created_at.hour,
    }

    features = pd.DataFrame([feature_values])[FEATURE_COLUMNS]
    probability_credible = model.predict_proba(features)[0][1]
    score_percent = round(float(probability_credible) * 100, 2)
    band = _band_for_score(score_percent)

    return AICredibilityScore.objects.create(
        incident=cluster,
        score_percent=score_percent,
        score_level=band,
        feature_inputs=feature_values,
        model_version='random_forest_v1',
    )
