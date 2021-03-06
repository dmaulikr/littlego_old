// -----------------------------------------------------------------------------
// Copyright 2011-2012 Patrick Näf (herzbube@herzbube.ch)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// -----------------------------------------------------------------------------


// Project includes
#import "EditGtpEngineProfileController.h"
#import "../main/ApplicationDelegate.h"
#import "../player/GtpEngineProfile.h"
#import "../player/GtpEngineProfileModel.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/TableViewSliderCell.h"
#import "../ui/UiUtilities.h"
#import "../ui/UiElementMetrics.h"
#import "../utility/UiColorAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Edit Profile" table view.
// -----------------------------------------------------------------------------
enum EditGtpEngineProfileTableViewSection
{
  ProfileNameSection,
  ProfileDescriptionSection,
  MaxMemorySection,
  OtherProfileSettingsSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ProfileNameSection.
// -----------------------------------------------------------------------------
enum ProfileNameSectionItem
{
  ProfileNameItem,
  MaxProfileNameSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ProfileDescriptionSection.
// -----------------------------------------------------------------------------
enum ProfileDescriptionSectionItem
{
  ProfileDescriptionItem,
  MaxProfileDescriptionSectionItem,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the MaxMemorySection.
// -----------------------------------------------------------------------------
enum MaxMemorySectionItem
{
  FuegoMaxMemoryItem,
  MaxMaxMemorySectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the OtherProfileSettingsSection.
// -----------------------------------------------------------------------------
enum OtherProfileSettingsSectionItem
{
  FuegoThreadCountItem,
  FuegoPonderingItem,
  FuegoReuseSubtreeItem,
  MaxOtherProfileSettingsSectionItem
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for
/// EditGtpEngineProfileController.
// -----------------------------------------------------------------------------
@interface EditGtpEngineProfileController()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name UIViewController methods
//@{
- (void) viewDidLoad;
- (void) viewDidUnload;
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
//@}
/// @name Action methods
//@{
- (void) create:(id)sender;
- (void) togglePondering:(id)sender;
- (void) toggleReuseSubtree:(id)sender;
- (void) maxMemoryDidChange:(id)sender;
- (void) threadCountDidChange:(id)sender;
//@}
/// @name UITableViewDataSource protocol
//@{
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView;
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section;
- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section;
- (NSString*) tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section;
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name UITableViewDelegate protocol
//@{
- (CGFloat) tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath;
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name UITextFieldDelegate protocol
//@{
- (BOOL) textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string;
//@}
/// @name EditTextDelegate protocol
//@{
- (bool) controller:(EditTextController*)editTextController shouldEndEditingWithText:(NSString*)text;
- (void) didEndEditing:(EditTextController*)editTextController didCancel:(bool)didCancel;
//@}
/// @name Private helpers
//@{
- (bool) isProfileValid;
//@}
/// @name Privately declared properties
//@{
@property(nonatomic, retain) UISwitch* reuseSubtreeSwitch;
//@}
@end


@implementation EditGtpEngineProfileController

@synthesize delegate;
@synthesize profile;
@synthesize profileExists;
@synthesize reuseSubtreeSwitch;


// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a EditGtpEngineProfileController
/// instance of grouped style that is used to edit @a profile.
// -----------------------------------------------------------------------------
+ (EditGtpEngineProfileController*) controllerForProfile:(GtpEngineProfile*)profile withDelegate:(id<EditGtpEngineProfileDelegate>)delegate
{
  EditGtpEngineProfileController* controller = [[EditGtpEngineProfileController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    controller.delegate = delegate;
    controller.profile = profile;
    controller.profileExists = true;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates an EditGtpEngineProfileController
/// instance of grouped style that is used to create a new GtpEngineProfile
/// object and edit its attributes.
// -----------------------------------------------------------------------------
+ (EditGtpEngineProfileController*) controllerWithDelegate:(id<EditGtpEngineProfileDelegate>)delegate
{
  EditGtpEngineProfileController* controller = [[EditGtpEngineProfileController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    controller.delegate = delegate;
    controller.profile = [[[GtpEngineProfile alloc] init] autorelease];
    controller.profileExists = false;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this EditGtpEngineProfileController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.delegate = nil;
  self.profile = nil;
  self.reuseSubtreeSwitch = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Called after the controller’s view is loaded into memory, usually
/// to perform additional initialization steps.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  if (self.profileExists)
  {
    self.navigationItem.title = @"Edit Profile";
    self.navigationItem.leftBarButtonItem.enabled = [self isProfileValid];
  }
  else
  {
    self.navigationItem.title = @"New Profile";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Create"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(create:)];
    self.navigationItem.rightBarButtonItem.enabled = [self isProfileValid];
  }
}

// -----------------------------------------------------------------------------
/// @brief Called when the controller’s view is released from memory, e.g.
/// during low-memory conditions.
///
/// Releases additional objects (e.g. by resetting references to retained
/// objects) that can be easily recreated when viewDidLoad() is invoked again
/// later.
// -----------------------------------------------------------------------------
- (void) viewDidUnload
{
  [super viewDidUnload];
}

// -----------------------------------------------------------------------------
/// @brief Called by UIKit at various times to determine whether this controller
/// supports the given orientation @a interfaceOrientation.
// -----------------------------------------------------------------------------
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return [UiUtilities shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
  return MaxSection;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
  switch (section)
  {
    case ProfileNameSection:
      return MaxProfileNameSectionItem;
    case ProfileDescriptionSection:
      return MaxProfileDescriptionSectionItem;
    case MaxMemorySection:
      return MaxMaxMemorySectionItem;
    case OtherProfileSettingsSection:
      return MaxOtherProfileSettingsSectionItem;
    default:
      assert(0);
      break;
  }
  return 0;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
  switch (section)
  {
    case ProfileNameSection:
      return @"Profile name & description";
    case ProfileDescriptionSection:
      return nil;
    case MaxMemorySection:
      return @"GTP engine settings";
    default:
      assert(0);
      break;
  }
  return nil;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSString*) tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
  switch (section)
  {
    case MaxMemorySection:
      return @"WARNING: Setting this value too high WILL crash the app! Read more about this under 'Help > Players & Profiles > Maximum memory'";
    case OtherProfileSettingsSection:
      return @"Changed settings are applied only after a new game with a player who uses this profile is started.";
    default:
      break;
  }
  return nil;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* cell;
  switch (indexPath.section)
  {
    case ProfileNameSection:
    {
      switch (indexPath.row)
      {
        case ProfileNameItem:
        {
          enum TableViewCellType cellType = TextFieldCellType;
          cell = [TableViewCellFactory cellWithType:cellType tableView:tableView];
          UITextField* textField = (UITextField*)[cell viewWithTag:TextFieldCellTextFieldTag];
          textField.delegate = self;
          textField.text = self.profile.name;
          textField.placeholder = @"Profile name";
          break;
        }
        default:
        {
          assert(0);
          break;
        }
      }
      break;
    }
    case ProfileDescriptionSection:
    {
      switch (indexPath.row)
      {
        case ProfileDescriptionItem:
        {
          enum TableViewCellType cellType = DefaultCellType;
          cell = [TableViewCellFactory cellWithType:cellType tableView:tableView];
          if (self.profile.profileDescription.length > 0)
          {
            cell.textLabel.text = self.profile.profileDescription;
            cell.textLabel.textColor = [UIColor slateBlueColor];
          }
          else
          {
            // Fake placeholder of UITextField
            cell.textLabel.text = @"Profile description";
            cell.textLabel.textColor = [UIColor lightGrayColor];
          }
          cell.textLabel.font = [UIFont systemFontOfSize:[UIFont labelFontSize]];  // remove bold'ness
          cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
          cell.textLabel.numberOfLines = 0;
          cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
          break;
        }
        default:
        {
          assert(0);
          break;
        }
      }
      break;
    }
    case MaxMemorySection:
    {
      cell = [TableViewCellFactory cellWithType:SliderCellType tableView:tableView];
      TableViewSliderCell* sliderCell = (TableViewSliderCell*)cell;
      [sliderCell setDelegate:self actionValueDidChange:nil actionSliderValueDidChange:@selector(maxMemoryDidChange:)];
      sliderCell.descriptionLabel.text = @"Max. memory (MB)";
      sliderCell.slider.minimumValue = fuegoMaxMemoryMinimum;
      sliderCell.slider.maximumValue = fuegoMaxMemoryMaximum;
      sliderCell.value = self.profile.fuegoMaxMemory;
      break;
    }
    case OtherProfileSettingsSection:
    {
      switch (indexPath.row)
      {
        case FuegoThreadCountItem:
        {
          cell = [TableViewCellFactory cellWithType:SliderCellType tableView:tableView];
          TableViewSliderCell* sliderCell = (TableViewSliderCell*)cell;
          [sliderCell setDelegate:self actionValueDidChange:nil actionSliderValueDidChange:@selector(threadCountDidChange:)];
          sliderCell.descriptionLabel.text = @"Number of threads";
          sliderCell.slider.minimumValue = fuegoThreadCountMinimum;
          sliderCell.slider.maximumValue = fuegoThreadCountMaximum;
          sliderCell.value = self.profile.fuegoThreadCount;
          break;
        }
        case FuegoPonderingItem:
        {
          cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
          UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
          cell.textLabel.text = @"Pondering";
          accessoryView.on = self.profile.fuegoPondering;
          [accessoryView addTarget:self action:@selector(togglePondering:) forControlEvents:UIControlEventValueChanged];
          break;
        }
        case FuegoReuseSubtreeItem:
        {
          cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
          UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
          cell.textLabel.text = @"Reuse subtree";
          accessoryView.on = self.profile.fuegoReuseSubtree;
          [accessoryView addTarget:self action:@selector(toggleReuseSubtree:) forControlEvents:UIControlEventValueChanged];
          // If pondering is on, the default value of reuse subtree ("on") must
          // not be changed by the user
          accessoryView.enabled = ! self.profile.fuegoPondering;
          // Keep reference to control so that we can manipulate it when
          // pondering is changed later on
          self.reuseSubtreeSwitch = accessoryView;
          break;
        }
      }
      break;
    }
    default:
    {
      assert(0);
      break;
    }
  }

  return cell;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (CGFloat) tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
  CGFloat height = tableView.rowHeight;
  switch (indexPath.section)
  {
    case ProfileDescriptionSection:
    {
      NSString* cellText;  // use the same strings as in tableView:cellForRowAtIndexPath:()
      if (ProfileNameSection == indexPath.section)
        cellText = self.profile.name;
      else
        cellText = self.profile.profileDescription;
      height = [UiUtilities tableView:tableView
                  heightForCellOfType:DefaultCellType
                             withText:cellText
               hasDisclosureIndicator:true];
      break;
    }
    case MaxMemorySection:
    {
      height = [TableViewSliderCell rowHeightInTableView:tableView];
      break;
    }
    case OtherProfileSettingsSection:
    {
      switch (indexPath.row)
      {
        case FuegoThreadCountItem:
        {
          height = [TableViewSliderCell rowHeightInTableView:tableView];
          break;
        }
        default:
        {
          break;
        }
      }
      break;
    }
    default:
    {
      break;
    }
  }
  return height;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];

  if (ProfileDescriptionSection == indexPath.section)
  {
    EditTextController* editTextController = [[EditTextController controllerWithText:self.profile.profileDescription
                                                                               style:EditTextControllerStyleTextView
                                                                            delegate:self] retain];
    editTextController.title = @"Edit description";
    UINavigationController* navigationController = [[UINavigationController alloc]
                                                    initWithRootViewController:editTextController];
    navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentModalViewController:navigationController animated:YES];
    [navigationController release];
    [editTextController release];
  }
}

// -----------------------------------------------------------------------------
/// @brief EditTextDelegate protocol method
// -----------------------------------------------------------------------------
- (bool) controller:(EditTextController*)editTextController shouldEndEditingWithText:(NSString*)text
{
  return true;
}

// -----------------------------------------------------------------------------
/// @brief EditTextDelegate protocol method
// -----------------------------------------------------------------------------
- (void) didEndEditing:(EditTextController*)editTextController didCancel:(bool)didCancel;
{
  if (! didCancel)
  {
    if (editTextController.textHasChanged)
    {
      self.profile.profileDescription = editTextController.text;
      NSIndexPath* indexPath = [NSIndexPath indexPathForRow:ProfileDescriptionItem inSection:ProfileDescriptionSection];
      NSArray* indexPaths = [NSArray arrayWithObject:indexPath];
      [self.tableView reloadRowsAtIndexPaths:indexPaths
                            withRowAnimation:UITableViewRowAnimationNone];
    }
  }
  [self dismissModalViewControllerAnimated:YES];
}

// -----------------------------------------------------------------------------
/// @brief UITextFieldDelegate protocol method.
///
/// An alternative to using the delegate protocol is to listen for notifications
/// sent by the text field.
// -----------------------------------------------------------------------------
- (BOOL) textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string
{
  // Compose the string as it would look like if the proposed change had already
  // been made
  NSString* newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
  self.profile.name = newText;
  if (self.profileExists)
  {
    // Make sure that the editing view cannot be left, unless the profile
    // is valid
    [self.navigationItem setHidesBackButton:! [self isProfileValid] animated:YES];
    // Notify delegate that something about the profile object has changed
    [self.delegate didChangeProfile:self];
  }
  else
  {
    // Make sure that the new profile cannot be added, unless it is valid
    self.navigationItem.rightBarButtonItem.enabled = [self isProfileValid];
  }
  // Accept all changes, even those that make the profile name invalid
  // -> the user must simply continue editing until the profile name becomes
  //    valid
  return YES;
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the user wants to create a new profile object using the
/// data that has been entered so far.
// -----------------------------------------------------------------------------
- (void) create:(id)sender
{
  GtpEngineProfileModel* model = [ApplicationDelegate sharedDelegate].gtpEngineProfileModel;
  [model add:self.profile];

  [self.delegate didCreateProfile:self];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Ponder" switch. Updates the profile
/// object with the new value.
// -----------------------------------------------------------------------------
- (void) togglePondering:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.profile.fuegoPondering = accessoryView.on;

  if (self.profileExists)
    [self.delegate didChangeProfile:self];

  // Directly manipulating the switch control gives the best result,
  // graphics-wise. If we do the update via table view reload of a single cell,
  // there is a nasty little flicker when pondering is turned off and the
  // "reuse subtree" switch becomes enabled. I have not tracked down the source
  // of the flicker, but instead gone straight to directly manipulating the
  // switch control.
  if (self.profile.fuegoPondering)
  {
    self.profile.fuegoReuseSubtree = true;
    self.reuseSubtreeSwitch.on = true;
  }
  self.reuseSubtreeSwitch.enabled = ! self.profile.fuegoPondering;
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Reuse subtree" switch. Updates the
/// profile object with the new value.
// -----------------------------------------------------------------------------
- (void) toggleReuseSubtree:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.profile.fuegoReuseSubtree = accessoryView.on;

  if (self.profileExists)
    [self.delegate didChangeProfile:self];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user changing Fuego's maximum amount of memory.
// -----------------------------------------------------------------------------
- (void) maxMemoryDidChange:(id)sender
{
  TableViewSliderCell* sliderCell = (TableViewSliderCell*)sender;
  self.profile.fuegoMaxMemory = sliderCell.value;

  if (self.profileExists)
    [self.delegate didChangeProfile:self];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user changing Fuego's number of threads.
// -----------------------------------------------------------------------------
- (void) threadCountDidChange:(id)sender
{
  TableViewSliderCell* sliderCell = (TableViewSliderCell*)sender;
  self.profile.fuegoThreadCount = sliderCell.value;

  if (self.profileExists)
    [self.delegate didChangeProfile:self];
}

// -----------------------------------------------------------------------------
/// @brief Returns true if the current profile object contains valid data so
/// that editing can safely be stopped.
// -----------------------------------------------------------------------------
- (bool) isProfileValid
{
  return (self.profile.name.length > 0);
}

@end
