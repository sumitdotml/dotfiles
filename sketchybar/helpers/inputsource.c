// Prints the current keyboard input source ID, including IMEs (e.g. Japanese).
// AppleCurrentKeyboardLayoutInputSourceID (used before) ignores IMEs, so it
// wrongly showed "EN" while typing Japanese. TIS reports the real active source.
#include <Carbon/Carbon.h>
#include <stdio.h>

int main(void) {
  TISInputSourceRef src = TISCopyCurrentKeyboardInputSource();
  if (!src) return 1;
  CFStringRef id = (CFStringRef)TISGetInputSourceProperty(src, kTISPropertyInputSourceID);
  char buf[256];
  if (id && CFStringGetCString(id, buf, sizeof(buf), kCFStringEncodingUTF8))
    printf("%s\n", buf);
  CFRelease(src);
  return 0;
}
