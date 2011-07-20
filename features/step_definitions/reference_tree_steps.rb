Then /^I should see a node "([^"]*)" at the root level in my reference tree "([^"]*)"$/ do |node_text, reference_tree_title|
  reference_tree = ReferenceTree.find_by_title(reference_tree_title)
  page.should have_css("div##{dom_id(reference_tree, "container_for")}>ul>li>a:contains('#{node_text}')")
end

Then /^I should see an? "([^"]*)" tab$/ do |tab_name|
  page.should have_css("ul.ui-tabs-nav > li:first-child > ul > li a:contains('#{tab_name}')")
end

Then /^I should see the breadcrumb path "([^"]*)"$/ do |path|
  parts = path.split(' > ')
  parts.each_with_index do |part, index|
    page.should have_css("#treewrap-right .ui-tabs-panel .breadcrumbs li:nth-child(#{index + 1}):contains('#{part}')")
  end
end

Then /^I should not be able to show a context menu for my reference tree "(.*)"$/ do |reference_tree_title|
  reference_tree = ReferenceTree.find_by_title(reference_tree_title)
  reference_tree_matcher = "div##{dom_id(reference_tree, "container_for")}"
  page.should have_css(reference_tree_matcher)

  page.execute_script("jQuery('#{reference_tree_matcher}').jstree('show_contextmenu');");
  sleep 1
  lambda { find_link('Rename') }.should raise_error
  lambda { find_link('New child') }.should raise_error
end

When /^I drag "([^"]*)" in my reference tree "(.*)" to "([^"]*)" in my master tree$/ do |origin_node_text, reference_tree_title, destination_node_text|
  reference_tree         = ReferenceTree.find_by_title(reference_tree_title)
  # we had a namespace conflict with Capybara::Node
  origin_node            = ::Node.joins(:name).where('names.name_string = ? AND nodes.tree_id = ?', origin_node_text, reference_tree.id).first
  destination_node       = ::Node.joins(:name).where('names.name_string = ?', destination_node_text).first
  
  When %{I select the node "#{origin_node.name_string}"}
  sleep 1
  page.execute_script("jQuery('#master-tree').jstree('move_node', '##{origin_node.id}', '##{destination_node.id}', 'first', true);")
end

When /^I drag "([^"]*)" to "([^"]*)" in my reference tree "(.*)"$/ do |origin_node_text, destination_node_text, reference_tree_title|
  reference_tree         = ReferenceTree.find_by_title(reference_tree_title)
  reference_tree_matcher = "div##{dom_id(reference_tree, "container_for")}"
  # we had a namespace conflict with Capybara::Node
  origin_node            = ::Node.joins(:name).where('names.name_string = ?', origin_node_text).first
  destination_node       = ::Node.joins(:name).where('names.name_string = ?', destination_node_text).first

  When %{I select the node "#{origin_node.name_string}"}
  sleep 1
  page.execute_script("jQuery('#{reference_tree_matcher}').jstree('move_node', '##{origin_node.id}', '##{destination_node.id}', 'first', false);")
end

When /^I drag selected nodes in my reference tree "(.*)" to "([^"]*)" in my master tree$/ do |reference_tree_title, destination_node_text|
  reference_tree         = ReferenceTree.find_by_title(reference_tree_title)
  reference_tree_matcher = "div##{dom_id(reference_tree, "container_for")}"
  destination_node       = ::Node.joins(:name).where('names.name_string = ?', destination_node_text).first
  
  page.execute_script("jQuery('#master-tree').jstree('move_node', '.jstree-clicked:parent', '##{destination_node.id}', 'first', true);")
end

When /^I refresh the reference tree "(.*)"$/ do |reference_tree_title|
  reference_tree = ReferenceTree.find_by_title(reference_tree_title)
  reference_tree_matcher = "div##{dom_id(reference_tree, "container_for")}"
  page.should have_css(reference_tree_matcher)

  page.execute_script("jQuery('#{reference_tree_matcher}').jstree('refresh');");
  sleep 1
end

When /^I select the node "([^"]*)" in my reference tree$/ do |node_text|
  When %{I follow "#{node_text}" within ".reference-tree-container"}
  sleep 1
end

When /^I expand the node "([^"]*)" in my reference tree "(.*)"$/ do |node_name, reference_tree_title|
  reference_tree = ReferenceTree.find_by_title(reference_tree_title)
  node = ::Node.joins(:name).where('names.name_string = ? and nodes.tree_id = ?', node_name, reference_tree.id).first
  page.execute_script("jQuery('.reference-tree-container > div').jstree('open_node', '##{node.id}');")
  sleep 1
end

When /^I wait for the reference tree to load$/ do
  loaded = false
  When %{pause 1}
  while !loaded
    loaded = page.has_css?(".reference-tree-container > div.loaded") && !page.has_css?("span.jstree-loading")
  end
end
