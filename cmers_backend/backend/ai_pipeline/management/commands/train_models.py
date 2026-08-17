from django.core.management.base import BaseCommand

from ai_pipeline.credibility import train_credibility_model
from ai_pipeline.severity import train_severity_model


class Command(BaseCommand):
    help = 'Trains and saves the credibility (Random Forest) and severity (XGBoost) models.'

    def handle(self, *args, **options):
        train_credibility_model()
        train_severity_model()
        self.stdout.write(self.style.SUCCESS('Both models trained and saved.'))
