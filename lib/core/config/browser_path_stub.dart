/// No-op on mobile and desktop. Web replaces this file.
void setBrowserPath(String path) {}

void listenBrowserPath(void Function() onChange) {}

/// Always false off the web.
bool browserWantsSignUp() => false;

/// Always false off the web.
bool browserWantsLogin() => false;
