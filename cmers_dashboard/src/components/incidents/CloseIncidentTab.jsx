import { App, Button, Form, Input, Popconfirm, Radio } from 'antd';
import { useState } from 'react';
import { closeIncident } from '../../api/incidents.api';
import { COLORS } from '../../theme';
import { CLOSE_SEVERITY_OPTIONS } from '../../utils/constants';

export default function CloseIncidentTab({ incident, onClosed }) {
  const { notification } = App.useApp();
  const [form] = Form.useForm();
  const [submitting, setSubmitting] = useState(false);

  function handleFinish(values) {
    setSubmitting(true);
    closeIncident(incident.id, values.actual_severity, values.note)
      .then((updated) => {
        notification.success({ message: 'Incident closed' });
        onClosed(updated);
      })
      .catch((err) => notification.error({ message: 'Close failed', description: err.message }))
      .finally(() => setSubmitting(false));
  }

  return (
    <Form form={form} layout="vertical" onFinish={handleFinish}>
      <Form.Item
        label="Actual severity"
        name="actual_severity"
        rules={[{ required: true, message: 'Select the actual severity' }]}
      >
        <Radio.Group>
          {CLOSE_SEVERITY_OPTIONS.map((opt) => (
            <Radio.Button key={opt.value} value={opt.value} style={{ color: COLORS.severity[opt.value] }}>
              {opt.label}
            </Radio.Button>
          ))}
        </Radio.Group>
      </Form.Item>

      <Form.Item label="Notes" name="note">
        <Input.TextArea rows={4} placeholder="Optional closing notes..." />
      </Form.Item>

      <Form.Item shouldUpdate>
        {() => (
          <Popconfirm
            title="Close this incident?"
            description="Are you sure? This will close the incident and record the actual severity as a training label for the AI models."
            onConfirm={() => form.submit()}
            okText="Yes"
            cancelText="Cancel"
          >
            <Button danger type="primary" loading={submitting}>
              Close Incident
            </Button>
          </Popconfirm>
        )}
      </Form.Item>
    </Form>
  );
}
