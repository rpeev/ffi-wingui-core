require 'windows_gui'

include WindowsGUI

def OnCreate(hwnd,
	cs
)
	SetLayeredWindowAttributes(hwnd, 0, 128, LWA_ALPHA)

	0
end

def OnDestroy(hwnd)
	PostQuitMessage(0); 0
end

WindowProc = FFI::Function.new(:long,
	[:pointer, :uint, :uint, :long],
	convention: :stdcall
) { |hwnd, uMsg, wParam, lParam|
begin
	result = case uMsg
	when WM_CREATE
		OnCreate(hwnd, CREATESTRUCT.new(FFI::Pointer.new(lParam)))
	when WM_DESTROY
		OnDestroy(hwnd)
	end

	result || DefWindowProc(hwnd, uMsg, wParam, lParam)
rescue SystemExit => ex
	PostQuitMessage(ex.status)
rescue
	case MessageBox(hwnd,
		L(FormatException($!)),
		APPNAME,
		MB_ABORTRETRYIGNORE | MB_ICONERROR
	)
	when IDABORT
		PostQuitMessage(2)
	when IDRETRY
		retry
	end
end
}

def WinMain
	UsingFFIStructs(WNDCLASSEX.new) { |wc|
		wc[:cbSize] = wc.size
		wc[:lpfnWndProc] = WindowProc
		wc[:hInstance] = GetModuleHandle(nil)
		wc[:hIcon] = LoadIcon(nil, IDI_APPLICATION)
		wc[:hCursor] = LoadCursor(nil, IDC_ARROW)
		wc[:hbrBackground] = FFI::Pointer.new(COLOR_WINDOW + 1)

		UsingFFIMemoryPointers(PWSTR(APPNAME)) { |className|
			wc[:lpszClassName] = className

			DetonateLastError(0, :RegisterClassEx,
				wc
			)
		}
	}

	hwnd = CreateWindowEx(
		WS_EX_LAYERED, APPNAME, APPNAME, WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN,
		CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,
		nil, nil, GetModuleHandle(nil), nil
	)

	raise "CreateWindowEx failed (last error: #{GetLastError()})" if
		hwnd.null? && GetLastError() != 0

	exit(0) if hwnd.null?

	ShowWindow(hwnd, SW_SHOWNORMAL)
	UpdateWindow(hwnd)

	UsingFFIStructs(MSG.new) { |msg|
		until DetonateLastError(-1, :GetMessage,
			msg, nil, 0, 0
		) == 0
			TranslateMessage(msg)
			DispatchMessage(msg)
		end

		exit(msg[:wParam])
	}
rescue
	MessageBox(hwnd,
		L(FormatException($!)),
		APPNAME,
		MB_ICONERROR
	); exit(1)
end

WinMain()
