from celery import shared_task


@shared_task
def run_ai_pipeline_task(report_id):
    from .orchestrator import run_pipeline
    result = run_pipeline(report_id)
    print(f'[AI Pipeline] report {report_id}: {result}')
    return result
