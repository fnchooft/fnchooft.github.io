-- 00_init.sql
-- Enable the ltree extension and create the generic_tree table.

\echo 'Creating ltree extension...'
CREATE EXTENSION IF NOT EXISTS ltree;

\echo 'Creating generic_tree table...'
CREATE TABLE generic_tree (
    id SERIAL PRIMARY KEY,
    path LTREE NOT NULL,
    node_type VARCHAR(50) NOT NULL,
    value TEXT NOT NULL,
    type VARCHAR(50) NOT NULL,
    metadata JSONB
);

CREATE INDEX generic_tree_path_gist_idx ON generic_tree USING GIST (path);
CREATE INDEX generic_tree_node_type_idx ON generic_tree (node_type);

\echo 'Schema initialized.'
