require 'spec_helper'

describe ActionMoveNodeWithinTree do

  subject { create(:action_move_node_within_tree) }

  it 'should return node' do
    subject.node.should == Node.find(subject.node_id)
  end

  it 'should return master_tree' do
    subject.master_tree.should == subject.node.tree
  end

  it 'should move the node on first perform and move it back on second perform' do
    node = subject.node
    old_parent_id = node.parent_id
    new_parent_id = subject.destination_parent_id
    ActionMoveNodeWithinTree.perform(subject.id)
    node.reload.parent_id.should == new_parent_id
    subject.reload.undo?.should be_truthy
    ActionMoveNodeWithinTree.perform(subject.id)
    node.reload.parent_id.should == old_parent_id
    subject.reload.undo?.should be_falsey
  end

  it 'should not try to move the node if node does not exist' do
    subject = create(:action_move_node_within_tree)
    node = subject.node
    node.destroy
    expect { ActionMoveNodeWithinTree.perform(subject.id) }.to raise_error
  end

  it 'should not try to move the node if destination does not exist' do
    subject = create(:action_move_node_within_tree)
    dest_node = Node.find(subject.destination_parent_id)
    dest_node.destroy
    expect { ActionMoveNodeWithinTree.perform(subject.id) }.to raise_error
  end

  it 'should not try to move the node if parent_id does not exist' do
    subject = create(:action_move_node_within_tree)
    parent_node = Node.find(subject.parent_id)
    parent_node.destroy
    expect { ActionMoveNodeWithinTree.perform(subject.id) }.to raise_error
  end

  it 'should not try to move the node if ancestry of parent is broken' do
    subject = create(:action_move_node_within_tree)
    parent_node = Node.find(subject.parent_id)
    parent_node.parent = create(:node)
    expect { ActionMoveNodeWithinTree.perform(subject.id) }.to raise_error
  end

  it 'should not try to move the node if ancestry of destination parent is broken' do
    subject = create(:action_move_node_within_tree)
    dest_node = Node.find(subject.destination_parent_id)
    dest_node.parent = create(:node)
    expect { ActionMoveNodeWithinTree.perform(subject.id) }.to raise_error
  end

  it 'should not try to move the node if parent and destination are in different trees' do
    subject = create(:action_move_node_within_tree, destination_parent_id: create(:node).id)
    expect { ActionMoveNodeWithinTree.perform(subject.id) }.to raise_error
  end

  it 'should not try to undo a move of the node if node does not exist' do
    subject = create(:action_move_node_within_tree, undo: true)
    subject.undo.should == true
    node = subject.node
    node.destroy
    expect { ActionMoveNodeWithinTree.perform(subject.id) }.to raise_error
  end

  it 'should not try to undo a move of the node if destination does not exist' do
    subject = create(:action_move_node_within_tree, undo: true)
    dest_node = Node.find(subject.destination_parent_id)
    dest_node.destroy
    expect { ActionMoveNodeWithinTree.perform(subject.id) }.to raise_error
  end

  it 'should not try to undo a move of the node if parent_id does not exist' do
    subject = create(:action_move_node_within_tree, undo: true)
    parent_node = Node.find(subject.parent_id)
    parent_node.destroy
    expect { ActionMoveNodeWithinTree.perform(subject.id) }.to raise_error
  end

  it 'should not try to undo a move of the node if ancestry of parent is broken' do
    subject = create(:action_move_node_within_tree, undo: true)
    parent_node = Node.find(subject.parent_id)
    parent_node.parent = create(:node)
    expect { ActionMoveNodeWithinTree.perform(subject.id) }.to raise_error
  end

  it 'should not try to undo a move of the node if ancestry of destination parent is broken' do
    subject = create(:action_move_node_within_tree, undo: true)
    dest_node = Node.find(subject.destination_parent_id)
    dest_node.parent = create(:node)
    expect { ActionMoveNodeWithinTree.perform(subject.id) }.to raise_error
  end

  it 'should not try to undo a move of the node if parent and destination are in different trees' do
    subject = create(:action_move_node_within_tree, undo: true, destination_parent_id: create(:node).id)
    expect { ActionMoveNodeWithinTree.perform(subject.id) }.to raise_error
  end
end
