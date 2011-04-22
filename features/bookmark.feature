Feature: Manage bookmarks
  As a user
  I can manage bookmarks
  So that I can quickly navigate to stored places

  Background: I have a master tree
    Given I have signed in with "email@person.com/password"
    And "email@person.com" has created an existing master tree titled "Spiders" with:
      | Pardosa             |
      | Pardosa distincta   |
      | Pardosa moesta      |
      | Pardosa xerampelina |
    And there is an existing bookmark called "First bookmark" for a node "Pardosa distincta"
    And there is an existing bookmark called "Second bookmark" for a node "Pardosa moesta"
    And I am on the master tree index page
    When I follow "Spiders"
    And I wait for the tree to load
    And I drag "Pardosa distincta" under "Pardosa"
    And I drag "Pardosa moesta" under "Pardosa"
    And I drag "Pardosa xerampelina" under "Pardosa"

  @javascript
  Scenario: User can see a bookmark associated with nodes in the master tree
    When I follow "Bookmarks" within "toolbar"
    And I follow "Show bookmarks" within "toolbar"
    And pause 3
    Then I should see a bookmark "First bookmark" in master tree bookmarks
    And I should see a bookmark "Second bookmark" in master tree bookmarks

  @javascript
  Scenario: User can add a bookmark to a node in the master tree from the toolbar
    When I expand the node "Pardosa"
    And I select the node "Pardosa xerampelina"
    And I follow "Bookmarks" within "toolbar"
    And I follow "Add bookmark" within "toolbar"
    And I fill in "Name" with "My bookmark"
    And I press "Add bookmark"
    And I follow "Show bookmarks" within "toolbar"
    And pause 3
    Then I should see a bookmark "My bookmark" in master tree bookmarks

  @javascript
  Scenario: User can click a bookmark in the master tree and have searched name highlighted
    And I follow "Bookmarks" within "toolbar"
    And I follow "Show bookmarks" within "toolbar"
    And pause 3
    And I follow "First bookmark"
    And pause 2
    Then I should see a node "Pardosa distincta" under "Pardosa"
    And the "Pardosa distincta" tree node should be selected

  @javascript
  Scenario: User can add a bookmark using the context menu in the master tree
    When I expand the node "Pardosa"
    And I select the node "Pardosa xerampelina"
    And I click "Add bookmark" in the context menu
    And I fill in "Name" with "My bookmark"
    And I press "Add bookmark"
    And I follow "Bookmarks" within "toolbar"
    And I follow "Show bookmarks" within "toolbar"
    And pause 3
    Then I should see a bookmark "My bookmark" in master tree bookmarks

  @javascript
  Scenario: User can delete a bookmark in the master tree
    When I follow "Bookmarks" within "toolbar"
    And I follow "Show bookmarks" within "toolbar"
    And pause 3
    And I delete "First bookmark" in master tree bookmarks
    Then I should not see a bookmark "First bookmark" in master tree bookmarks
    And I should see a bookmark "Second bookmark" in master tree bookmarks
    And I click the master tree background
    And I follow "Bookmarks" within "toolbar"
    And I follow "Show bookmarks" within "toolbar"
    And pause 3
    Then I should not see a bookmark "First bookmark" in master tree bookmarks
    And I should see a bookmark "Second bookmark" in master tree bookmarks