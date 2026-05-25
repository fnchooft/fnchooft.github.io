-- test.sql
-- Runs a series of tests against the generate_xml_from_tree function.

-- This is a psql client command. It's in the right place.
\set ON_ERROR_STOP on

-- This \echo is also a client command, executed before the DO block.
\echo '--- Running Test Suite ---'

-- This entire block is sent to the server for execution.
DO $$
DECLARE
    test_result BOOLEAN;
    test_xml XML;
BEGIN
    -- Test 1: Full depth of a complex tree
    RAISE NOTICE 'Test 1: Full filesystem tree (ID 1, depth 4)';
    test_xml := generate_xml_from_tree(1, 4);
    test_result := xpath_exists('//filesystem[@id="8"]', test_xml);
    ASSERT test_result, 'FAIL: Deepest filesystem node not found.';
    RAISE NOTICE '[PASS] Test 1 completed.';

    -- Test 2: Limited depth
    RAISE NOTICE 'Test 2: Filesystem tree with limited depth (ID 1, depth 2)';
    test_xml := generate_xml_from_tree(1, 2);
    test_result := xpath_exists('//filesystem[@id="2"]', test_xml);
    ASSERT test_result, 'FAIL: Mid-level node "home" not found.';
    test_result := NOT xpath_exists('//filesystem[@id="3"]', test_xml);
    ASSERT test_result, 'FAIL: Deeper node "alice" was found, but should be excluded by depth.';
    RAISE NOTICE '[PASS] Test 2 completed.';

    -- Test 3: Starting from a subtree (organization chart)
    RAISE NOTICE 'Test 3: Subtree for organization (ID 11, depth 3)';
    test_xml := generate_xml_from_tree(11, 3);
    test_result := xpath_exists('/organization[@id="11"]', test_xml);
    ASSERT test_result, 'FAIL: Root node is not Bob Johnson (ID 11).';
    test_result := xpath_exists('//organization[@id="13"]', test_xml);
    ASSERT test_result, 'FAIL: Leaf node Diana Prince not found in subtree.';
    RAISE NOTICE '[PASS] Test 3 completed.';

    -- Test 4: Single node result (depth 1)
    RAISE NOTICE 'Test 4: Single node result (ID 22, depth 1)';
    
   test_xml := generate_xml_from_tree(22, 1);
    -- CORRECTED: The test now checks that the root element is correct and has no
    -- *recursive children of its own type*, which is the correct definition of a
    -- "single node result" for this function. It correctly allows for data children
    -- like <value> and elements from the metadata.
    test_result := xpath_exists('/app_config[@id="22" and not(app_config)]', test_xml);
    ASSERT test_result, 'FAIL: Result should be a single app_config node with no nested app_config children.';
    RAISE NOTICE '[PASS] Test 4 completed.';

    -- Test 5: Non-existent node ID
    RAISE NOTICE 'Test 5: Non-existent start node ID (ID 999, depth 3)';
    test_xml := generate_xml_from_tree(999, 3);
    ASSERT test_xml IS NULL, 'FAIL: Result for a non-existent node should be NULL.';
    RAISE NOTICE '[PASS] Test 5 completed.';

END $$;

-- This final \echo is a client command. It will only be reached if the DO block
-- above completes successfully because of '\set ON_ERROR_STOP on'.
\echo '--- All tests passed successfully! ---'