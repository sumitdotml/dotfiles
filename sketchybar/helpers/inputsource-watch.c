// Long-running watcher: fires a sketchybar event the instant the selected
// keyboard input source changes, so the bar's language indicator updates
// immediately instead of waiting for a poll. Uses the Carbon distributed
// notification (no Accessibility permission required).
#include <Carbon/Carbon.h>
#include <stdlib.h>

static void on_change(CFNotificationCenterRef center, void *observer,
                      CFNotificationName name, const void *object,
                      CFDictionaryRef userInfo) {
  system("sketchybar --trigger language_change 2>/dev/null");
}

int main(void) {
  CFNotificationCenterRef dnc = CFNotificationCenterGetDistributedCenter();
  CFNotificationCenterAddObserver(
      dnc, NULL, on_change,
      kTISNotifySelectedKeyboardInputSourceChanged, NULL,
      CFNotificationSuspensionBehaviorDeliverImmediately);
  CFRunLoopRun();
  return 0;
}
