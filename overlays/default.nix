final: prev: {
  skhd =
    prev.skhd.overrideAttrs (finalAttrs: previousAttrs: {
    });
  yabai = prev.yabai.overrideAttrs (finalAttrs: previousAttrs: {
    postPatch =
      ''
        substituteInPlace makefile \
          --replace "BUILD_FLAGS    = -std=c99 -Wall -g -O0 -fvisibility=hidden -mmacosx-version-min=11.0 -fno-objc-arc -arch x86_64 -arch arm64" "BUILD_FLAGS    = -std=c99 -Wall -g -O0 -fvisibility=hidden -mmacosx-version-min=11.0 -fno-objc-arc -arch x86_64 -arch arm64 -Wno-implicit-function-declaration" \
          --replace "asan: BUILD_FLAGS=-std=c99 -Wall -g -O0 -fvisibility=hidden -fsanitize=address,undefined -mmacosx-version-min=11.0 -fno-objc-arc -arch x86_64 -arch arm64" "asan: BUILD_FLAGS=-std=c99 -Wall -g -O0 -fvisibility=hidden -fsanitize=address,undefined -mmacosx-version-min=11.0 -fno-objc-arc -arch x86_64 -arch arm64 -Wno-implicit-function-declaration" \
          --replace "tsan: BUILD_FLAGS=-std=c99 -Wall -g -O0 -fvisibility=hidden -fsanitize=thread,undefined -mmacosx-version-min=11.0 -fno-objc-arc -arch x86_64 -arch arm64" "tsan: BUILD_FLAGS=-std=c99 -Wall -g -O0 -fvisibility=hidden -fsanitize=thread,undefined -mmacosx-version-min=11.0 -fno-objc-arc -arch x86_64 -arch arm64 -Wno-implicit-function-declaration" \
          --replace "install: BUILD_FLAGS=-std=c99 -Wall -DNDEBUG -O2 -fvisibility=hidden -mmacosx-version-min=11.0 -fno-objc-arc -arch x86_64 -arch arm64" "install: BUILD_FLAGS=-std=c99 -Wall -DNDEBUG -O2 -fvisibility=hidden -mmacosx-version-min=11.0 -fno-objc-arc -arch x86_64 -arch arm64 -Wno-implicit-function-declaration"
      ''
      + previousAttrs.postPatch;
  });
}
