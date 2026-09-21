/// No-op on mobile and desktop. Web replaces this file.
void setBrowserPath(String path) {}

void listenBrowserPath(void Function(bool signUp) onChange) {}

/// Always false off the web.
bool browserWantsSignUp() => false;
