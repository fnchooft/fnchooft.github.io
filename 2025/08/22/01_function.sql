-- 01_function.sql
-- Defines the function to convert a subtree from the generic_tree table to XML.

-- Creating generate_xml_from_tree function...

CREATE OR REPLACE FUNCTION generate_xml_from_tree(
    p_start_node_id INT,
    p_max_depth INT
)
RETURNS XML
LANGUAGE plpgsql
AS $$
DECLARE
    result_xml XML;
    start_level INT;
    max_level INT;
BEGIN
    -- CORRECTED: Ensure any lingering temp tables from a previous call
    -- within the same transaction are dropped before we begin.
    DROP TABLE IF EXISTS _subtree_nodes;
    DROP TABLE IF EXISTS _xml_build_step;

    -- Create temporary tables that will be automatically dropped at the end of the transaction.
    CREATE TEMP TABLE _subtree_nodes (
        id INT,
        path LTREE,
        node_type VARCHAR(50),
        value TEXT,
        type VARCHAR(50),
        metadata JSONB
    ) ON COMMIT DROP;

    CREATE TEMP TABLE _xml_build_step (
        path LTREE PRIMARY KEY,
        node_xml XML
    ) ON COMMIT DROP;

    -- 1. Identify the scope of nodes we care about and store them.
    WITH query_scope AS (
        SELECT path AS start_path
        FROM generic_tree
        WHERE id = p_start_node_id
    )
    INSERT INTO _subtree_nodes
    SELECT
        lc.id, lc.path, lc.node_type, lc.value, lc.type, lc.metadata
    FROM
        generic_tree lc, query_scope qs
    WHERE
        lc.path <@ qs.start_path
        AND (nlevel(lc.path) - nlevel(qs.start_path)) < p_max_depth;

    -- 2. Find the min and max levels in our filtered subtree to control the loop.
    SELECT MIN(nlevel(path)), MAX(nlevel(path))
    INTO start_level, max_level
    FROM _subtree_nodes;

    -- If no nodes were found, return NULL.
    IF max_level IS NULL THEN
        RETURN NULL;
    END IF;

    -- 3. Loop from the deepest level upwards.
    FOR current_level IN REVERSE max_level..start_level LOOP
        INSERT INTO _xml_build_step (path, node_xml)
        SELECT
            n.path,
            xmlparse(CONTENT
                '<' || n.node_type || format(' id="%s"', n.id) || format(' type="%s"', n.type) || '>'
                ||
                COALESCE((xmlconcat(
                    XMLFOREST(n.value),
                    (CASE
                        WHEN n.metadata IS NOT NULL THEN
                           (SELECT XMLAGG(xmlparse(CONTENT
                               '<' || key || '>'
                               || replace(replace(replace(replace(replace(value, '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&apos;')
                               || '</' || key || '>'
                            ))
                            FROM jsonb_each_text(n.metadata))
                        ELSE NULL
                    END),
                    (
                        SELECT XMLAGG(c.node_xml ORDER BY c.path)
                        FROM _xml_build_step AS c
                        WHERE c.path <@ n.path AND nlevel(c.path) = current_level + 1
                    )
                ))::text, '')
                ||
                '</' || n.node_type || '>'
            )
        FROM
            _subtree_nodes AS n
        WHERE
            nlevel(n.path) = current_level;
    END LOOP;

    -- 4. Select the final completed XML for our starting node.
    SELECT node_xml INTO result_xml
    FROM _xml_build_step
    JOIN _subtree_nodes ON _subtree_nodes.path = _xml_build_step.path
    WHERE _subtree_nodes.id = p_start_node_id;

    RETURN result_xml;
END;
$$;

-- Function created.