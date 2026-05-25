-- 02_data.sql
-- Inserts test data into the generic_tree table.

\echo 'Inserting test data...'

INSERT INTO generic_tree (id, path, node_type, value, type, metadata) VALUES
-- Overriding the serial ID so we have predictable IDs for testing
(1, '1',         'filesystem', '/',                'directory', '{"permissions": "drwxr-xr-x"}'),
(2, '1.1',       'filesystem', 'home',             'directory', '{"permissions": "drwxr-xr-x"}'),
(3, '1.1.1',     'filesystem', 'alice',            'directory', '{"owner": "alice", "permissions": "drwx------"}'),
(4, '1.1.1.1',   'filesystem', 'document.txt',     'file',      '{"size_kb": 12, "mime_type": "text/plain"}'),
(5, '1.1.1.2',   'filesystem', 'photo.jpg',        'file',      '{"size_kb": 2048, "mime_type": "image/jpeg"}'),
(6, '1.2',       'filesystem', 'etc',              'directory', '{"permissions": "drwxr-xr-x"}'),
(7, '1.2.1',     'filesystem', 'postgres',         'directory', '{"owner": "postgres", "permissions": "drwx------"}'),
(8, '1.2.1.1',   'filesystem', 'postgresql.conf',  'config_file', '{"size_kb": 28, "version": 16}'),

(10, '2',         'organization', 'Alice Smith',    'ceo',       '{"employee_id": 1}'),
(11, '2.1',       'organization', 'Bob Johnson',    'vp_engineering', '{"employee_id": 10}'),
(12, '2.1.1',     'organization', 'Charlie Brown',  'director',  '{"employee_id": 101, "team": "Platform"}'),
(13, '2.1.1.1',   'organization', 'Diana Prince',   'lead_dev',  '{"employee_id": 105, "specialty": "Databases"}'),
(14, '2.1.2',     'organization', 'Eve Williams',   'director',  '{"employee_id": 102, "team": "Frontend"}'),
(15, '2.2',       'organization', 'Frank Miller',   'vp_sales',  '{"employee_id": 12}'),
(16, '2.2.1',     'organization', 'Grace Lee',      'sales_manager', '{"employee_id": 201, "region": "North America"}'),

(20, '3',         'app_config', 'WebApp Settings', 'root',        NULL),
(21, '3.1',       'app_config', 'database',        'section',     NULL),
(22, '3.1.1',     'app_config', '5432',            'integer',     '{"name": "port", "required": true}'),
(23, '3.1.2',     'app_config', 'true',            'boolean',     '{"name": "enable_ssl", "required": false}'),
(24, '3.1.3',     'app_config', 'app_user',        'string',      '{"name": "username", "sensitive": true}'),
(25, '3.2',       'app_config', 'api_keys',        'section',     NULL),
(26, '3.2.1',     'app_config', 'abcdef123456',    'string',      '{"name": "google_maps", "sensitive": true}');
-- Manually update the sequence to avoid collisions with future inserts
SELECT setval('generic_tree_id_seq', (SELECT MAX(id) FROM generic_tree));

\echo 'Test data inserted.'
