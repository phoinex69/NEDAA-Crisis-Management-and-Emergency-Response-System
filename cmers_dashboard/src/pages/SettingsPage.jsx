import { EditOutlined, PlusOutlined, StopOutlined } from '@ant-design/icons';
import { App, Button, Form, Input, Modal, Select, Switch, Table, Tabs, Tag, Typography } from 'antd';
import { useEffect, useState } from 'react';
import {
  createOfficialAccount,
  createOrganization,
  getAccessRoles,
  getOfficialAccounts,
  getOrganizations,
  getUnits,
  updateOfficialAccount,
  updateOrganization,
} from '../api/resources.api';
import { useAuth } from '../hooks/useAuth';
import { ORG_TYPE_OPTIONS, getOrgTypeTag, getRoleTagColor } from '../utils/constants';
import { formatDate } from '../utils/formatters';

const { Title, Text } = Typography;

function useListData(fetcher) {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);

  function load() {
    setLoading(true);
    fetcher()
      .then((res) => setData(res.results ?? (Array.isArray(res) ? res : [])))
      .catch(() => setData([]))
      .finally(() => setLoading(false));
  }

  // eslint-disable-next-line react-hooks/exhaustive-deps
  useEffect(load, []);

  return { data, loading, reload: load };
}

function OrganizationsTab({ isAdmin }) {
  const { notification } = App.useApp();
  const orgs = useListData(getOrganizations);
  const units = useListData(getUnits);
  const [form] = Form.useForm();
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState(null);
  const [saving, setSaving] = useState(false);

  const unitCounts = units.data.reduce((acc, u) => {
    const key = u.organization;
    acc[key] = (acc[key] ?? 0) + 1;
    return acc;
  }, {});

  function openCreate() {
    setEditing(null);
    form.resetFields();
    setModalOpen(true);
  }

  function openEdit(record) {
    setEditing(record);
    form.setFieldsValue(record);
    setModalOpen(true);
  }

  function handleSave(values) {
    setSaving(true);
    const action = editing ? updateOrganization(editing.id, values) : createOrganization(values);
    action
      .then(() => {
        notification.success({ message: editing ? 'Organization updated' : 'Organization created' });
        setModalOpen(false);
        orgs.reload();
      })
      .catch((err) => notification.error({ message: 'Save failed', description: err.message }))
      .finally(() => setSaving(false));
  }

  const columns = [
    { title: 'Name', dataIndex: 'name' },
    {
      title: 'Type',
      dataIndex: 'organization_type',
      render: (value) => {
        const tag = getOrgTypeTag(value);
        return <Tag color={tag.tagColor}>{tag.label}</Tag>;
      },
    },
    {
      title: 'Units',
      key: 'units',
      render: (_, record) => unitCounts[record.id] ?? 0,
    },
    {
      title: 'Status',
      dataIndex: 'is_active',
      render: (value) => <Tag color={value ? 'green' : 'default'}>{value ? 'Active' : 'Inactive'}</Tag>,
    },
    { title: 'Created', dataIndex: 'created_at', render: (v) => formatDate(v) },
    ...(isAdmin
      ? [
          {
            title: 'Actions',
            key: 'actions',
            render: (_, record) => (
              <Button size="small" icon={<EditOutlined />} onClick={() => openEdit(record)}>
                Edit
              </Button>
            ),
          },
        ]
      : []),
  ];

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: 12 }}>
        {isAdmin && (
          <Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>
            Add Organization
          </Button>
        )}
      </div>
      <Table
        columns={columns}
        dataSource={orgs.data}
        rowKey="id"
        loading={orgs.loading}
        size="small"
        pagination={{ pageSize: 20 }}
      />

      <Modal
        title={editing ? 'Edit Organization' : 'Add Organization'}
        open={modalOpen}
        onCancel={() => setModalOpen(false)}
        onOk={() => form.submit()}
        confirmLoading={saving}
        destroyOnClose
      >
        <Form form={form} layout="vertical" onFinish={handleSave} initialValues={{ is_active: true }}>
          <Form.Item name="name" label="Name" rules={[{ required: true, message: 'Name is required' }]}>
            <Input />
          </Form.Item>
          <Form.Item
            name="organization_type"
            label="Type"
            rules={[{ required: true, message: 'Type is required' }]}
          >
            <Select options={ORG_TYPE_OPTIONS.map((o) => ({ value: o.value, label: o.label }))} />
          </Form.Item>
          <Form.Item name="contact_phone" label="Contact Phone">
            <Input />
          </Form.Item>
          <Form.Item name="email" label="Email">
            <Input />
          </Form.Item>
          <Form.Item name="address" label="Address">
            <Input />
          </Form.Item>
          <Form.Item name="is_active" label="Active" valuePropName="checked">
            <Switch />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
}

function OfficialAccountsTab({ isAdmin }) {
  const { notification } = App.useApp();
  const accounts = useListData(getOfficialAccounts);
  const orgs = useListData(getOrganizations);
  const roles = useListData(getAccessRoles);
  const [form] = Form.useForm();
  const [modalOpen, setModalOpen] = useState(false);
  const [saving, setSaving] = useState(false);

  function openCreate() {
    form.resetFields();
    setModalOpen(true);
  }

  function handleCreate(values) {
    setSaving(true);
    createOfficialAccount(values)
      .then(() => {
        notification.success({ message: 'Account created' });
        setModalOpen(false);
        accounts.reload();
      })
      .catch((err) => notification.error({ message: 'Create failed', description: err.message }))
      .finally(() => setSaving(false));
  }

  function toggleActive(record) {
    updateOfficialAccount(record.id, { is_active: !record.is_active })
      .then(() => {
        notification.success({ message: record.is_active ? 'Account deactivated' : 'Account activated' });
        accounts.reload();
      })
      .catch((err) => notification.error({ message: 'Update failed', description: err.message }));
  }

  const columns = [
    { title: 'Email', dataIndex: 'email' },
    { title: 'Organization', dataIndex: 'organization_name' },
    {
      title: 'Role',
      dataIndex: 'role_name',
      render: (value) => <Tag color={getRoleTagColor(value)}>{value ?? 'none'}</Tag>,
    },
    {
      title: 'Status',
      dataIndex: 'is_active',
      render: (value) => (
        <span style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <span
            style={{
              width: 8,
              height: 8,
              borderRadius: '50%',
              background: value ? '#16A34A' : '#94a3b8',
              display: 'inline-block',
            }}
          />
          {value ? 'Active' : 'Inactive'}
        </span>
      ),
    },
    { title: 'Created', dataIndex: 'created_at', render: (v) => formatDate(v) },
    ...(isAdmin
      ? [
          {
            title: 'Actions',
            key: 'actions',
            render: (_, record) => (
              <Button size="small" danger={record.is_active} icon={<StopOutlined />} onClick={() => toggleActive(record)}>
                {record.is_active ? 'Deactivate' : 'Activate'}
              </Button>
            ),
          },
        ]
      : []),
  ];

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: 12 }}>
        {isAdmin && (
          <Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>
            Create Account
          </Button>
        )}
      </div>
      <Table
        columns={columns}
        dataSource={accounts.data}
        rowKey="id"
        loading={accounts.loading}
        size="small"
        pagination={{ pageSize: 20 }}
      />

      <Modal
        title="Create Official Account"
        open={modalOpen}
        onCancel={() => setModalOpen(false)}
        onOk={() => form.submit()}
        confirmLoading={saving}
        destroyOnClose
      >
        <Form form={form} layout="vertical" onFinish={handleCreate} initialValues={{ is_active: true }}>
          <Form.Item name="email" label="Email" rules={[{ required: true, type: 'email', message: 'Valid email is required' }]}>
            <Input />
          </Form.Item>
          <Form.Item
            name="password"
            label="Password"
            rules={[{ required: true, min: 8, message: 'Password must be at least 8 characters' }]}
          >
            <Input.Password />
          </Form.Item>
          <Form.Item name="organization" label="Organization" rules={[{ required: true, message: 'Organization is required' }]}>
            <Select
              loading={orgs.loading}
              options={orgs.data.map((o) => ({ value: o.id, label: o.name }))}
            />
          </Form.Item>
          <Form.Item name="role" label="Role" rules={[{ required: true, message: 'Role is required' }]}>
            <Select loading={roles.loading} options={roles.data.map((r) => ({ value: r.id, label: r.name }))} />
          </Form.Item>
          <Form.Item name="designation" label="Designation">
            <Input />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
}

function SystemInfoTab() {
  const { account } = useAuth();
  const [sessionStart] = useState(() => new Date());

  const infoRows = [
    { label: 'System', value: 'NEDAA — Emergency Response Coordination' },
    { label: 'Environment', value: 'Development' },
    { label: 'Current Operator', value: account?.full_name || account?.email || 'Unknown' },
    { label: 'Role', value: account?.role_name ?? 'official' },
    { label: 'Organization', value: account?.organization_name ?? 'N/A' },
    { label: 'Session Started', value: formatDate(sessionStart.toISOString()) },
  ];

  return (
    <div style={{ background: '#fff', borderRadius: 8, boxShadow: 'var(--card-shadow)', padding: 24, maxWidth: 520 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 20 }}>
        <span style={{ width: 10, height: 10, borderRadius: '50%', background: '#16A34A', display: 'inline-block' }} />
        <Text strong>System Operational</Text>
      </div>
      {infoRows.map((row) => (
        <div
          key={row.label}
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            padding: '10px 0',
            borderBottom: '1px solid #f0f0f0',
          }}
        >
          <Text type="secondary">{row.label}</Text>
          <Text strong>{row.value}</Text>
        </div>
      ))}
    </div>
  );
}

export default function SettingsPage() {
  const { account } = useAuth();
  const isAdmin = account?.role_name === 'admin';

  return (
    <div>
      <Title level={3} style={{ marginBottom: 4 }}>
        Settings
      </Title>
      <Text type="secondary">Manage organizations, official accounts, and system information</Text>

      <Tabs
        style={{ marginTop: 16 }}
        items={[
          { key: 'organizations', label: 'Organizations', children: <OrganizationsTab isAdmin={isAdmin} /> },
          { key: 'accounts', label: 'Official Accounts', children: <OfficialAccountsTab isAdmin={isAdmin} /> },
          { key: 'system', label: 'System Info', children: <SystemInfoTab /> },
        ]}
      />
    </div>
  );
}
