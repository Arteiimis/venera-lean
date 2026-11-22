#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  // Impeller (the 3.47+ Windows default) measured 9-10x slower to first frame
  // and ~55% slower steady-state raster than the Skia path on this app's
  // scenes; see doc/lean-removals.md (batch 9). Re-measure with
  // tool/test_performance_windows.ps1 before removing this switch.
  project.set_impeller_switch(flutter::ImpellerSwitch::Disabled);

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  // Win32Window::Create treats a window with the same class and title as a
  // running instance and only foregrounds it. Keep the debug window's title
  // distinct so `flutter run -d windows` can coexist with the installed
  // release; the release title must stay "Venera Lean" unchanged.
#ifdef _DEBUG
  constexpr const wchar_t* kWindowTitle = L"Venera Lean (Dev)";
#else
  constexpr const wchar_t* kWindowTitle = L"Venera Lean";
#endif
  if (!window.Create(kWindowTitle, origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
