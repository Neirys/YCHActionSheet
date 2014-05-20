YCHActionSheet
==============

# Purpose
YCHActionSheet is a custom UIActionSheet visualy separated into sections.

# Installation
Simply drag YCHActionSheet.h and YCHActionSheet.m into your project and you are ready to go.

# How to use
The first step is to prepare your sections by creating `YCHActionSheetSection` objects using the following methods :
```ios
- (instancetype)initWithTitle:(NSString *)title otherButtonTitles:(NSString *)otherButtonTitles, ...;
``` 
or
```ios
+ (instancetype)sectionWithTitle:(NSString *)title otherButtonTitles:(NSString *)otherButtonTitles, ...;
```

You can also create a destructive section (unique button) by using :
```ios
+ (instancetype)destructiveSectionWithTitle:(NSString *)title;
```

Once your sections are ready, initialize a YCHActionSheet object using :
```ios
- (instancetype)initWithSections:(NSArray *)sections cancelButtonTitle:(NSString *)cancelButtonTitle delegate:(id<YCHActionSheetDelegate>)delegate;
```
then display it with :
```ios
- (void)showInView:(UIView *)view;
```

# Delegate
`YCHActionSheetDelegate` provides methods that can be used to intecept events. All those methods are optional.
```ios
// called when a button was clicked at section index and button index
- (void)actionSheet:(YCHActionSheet *)actionSheet clickedButtonAtIndex:(NSUInteger)buttonIndex sectionIndex:(NSUInteger)sectionIndex;

// called when a user clicked on the Cancel button
- (void)actionSheetDidCancel:(YCHActionSheet *)actionSheet;

// called before / after an action sheet is shown
- (void)willPresentActionSheet:(YCHActionSheet *)actionSheet;
- (void)didPresentActionSheet:(YCHActionSheet *)actionSheet;

// called before / after an action sheet is dismiss
- (void)willDismissActionSheet:(YCHActionSheet *)actionSheet;
- (void)didDismissActionSheet:(YCHActionSheet *)actionSheet;
``

# Improvements
At this moment, there is an ugly animation happening during rotation where we can clearly see buttons being resized.
I would appreciate if someone finds a way to remove this effect.

# MIT License
Copyright (c) 2014 Yaman JAIOUCH

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
   

# Release notes
Version 1.0
* Initial release