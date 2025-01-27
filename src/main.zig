//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

const c = @cImport(@cInclude("SDL3/SDL.h"));
const std = @import("std");
const builtin = @import("builtin");

// From SDL_video.h
// Translate-C seems to have trouble with SDL_UINT64_C() macro appending LL
// to these literals. A temporary work around to just write them in.
const SDL_WINDOW_FULLSCREEN: u64 = 0x0000000000000001; //**< window is in fullscreen mode */
const SDL_WINDOW_OPENGL: u64 = 0x0000000000000002; //**< window usable with OpenGL context */
const SDL_WINDOW_OCCLUDED: u64 = 0x0000000000000004; //**< window is occluded */
const SDL_WINDOW_HIDDEN: u64 = 0x0000000000000008; //**< window is neither mapped onto the desktop nor shown in the taskbar/dock/window list; SDL_ShowWindow() is required for it to become visible */
const SDL_WINDOW_BORDERLESS: u64 = 0x0000000000000010; //**< no window decoration */
const SDL_WINDOW_RESIZABLE: u64 = 0x0000000000000020; //**< window can be resized */
const SDL_WINDOW_MINIMIZED: u64 = 0x0000000000000040; //**< window is minimized */
const SDL_WINDOW_MAXIMIZED: u64 = 0x0000000000000080; //**< window is maximized */
const SDL_WINDOW_MOUSE_GRABBED: u64 = 0x0000000000000100; //**< window has grabbed mouse input */
const SDL_WINDOW_INPUT_FOCUS: u64 = 0x0000000000000200; //**< window has input focus */
const SDL_WINDOW_MOUSE_FOCUS: u64 = 0x0000000000000400; //**< window has mouse focus */
const SDL_WINDOW_EXTERNAL: u64 = 0x0000000000000800; //**< window not created by SDL */
const SDL_WINDOW_MODAL: u64 = 0x0000000000001000; //**< window is modal */
const SDL_WINDOW_HIGH_PIXEL_DENSITY: u64 = 0x0000000000002000; //**< window uses high pixel density back buffer if possible */
const SDL_WINDOW_MOUSE_CAPTURE: u64 = 0x0000000000004000; //**< window has mouse captured (unrelated to MOUSE_GRABBED) */
const SDL_WINDOW_MOUSE_RELATIVE_MODE: u64 = 0x0000000000008000; //**< window has relative mode enabled */
const SDL_WINDOW_ALWAYS_ON_TOP: u64 = 0x0000000000010000; //**< window should always be above others */
const SDL_WINDOW_UTILITY: u64 = 0x0000000000020000; //**< window should be treated as a utility window, not showing in the task bar and window list */
const SDL_WINDOW_TOOLTIP: u64 = 0x0000000000040000; //**< window should be treated as a tooltip and does not get mouse or keyboard focus, requires a parent window */
const SDL_WINDOW_POPUP_MENU: u64 = 0x0000000000080000; //**< window should be treated as a popup menu, requires a parent window */
const SDL_WINDOW_KEYBOARD_GRABBED: u64 = 0x0000000000100000; //**< window has grabbed keyboard input */
const SDL_WINDOW_VULKAN: u64 = 0x0000000010000000; //**< window usable for Vulkan surface */
const SDL_WINDOW_METAL: u64 = 0x0000000020000000; //**< window usable for Metal view */
const SDL_WINDOW_TRANSPARENT: u64 = 0x0000000040000000; //**< window with transparent buffer */
const SDL_WINDOW_NOT_FOCUSABLE: u64 = 0x0000000080000000; //**< window should not be focusable */

pub fn main() !void {
    if (!c.SDL_Init(c.SDL_INIT_VIDEO)) {
        c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    }
    defer c.SDL_Quit();

    //Use SDL_CreateWindowWithProperties if needing to set position
    //const screen = c.SDL_CreateWindow("Boiler Window", 400, 100, c.SDL_WINDOW_BORDERLESS) orelse {
    const sdl_window_type = switch (builtin.os.tag) {
        .macos => SDL_WINDOW_METAL,
        else => SDL_WINDOW_OPENGL,
    };
    const screen = c.SDL_CreateWindow("Boiler Window", 400, 140, sdl_window_type) orelse {
        c.SDL_Log("Unable to create window: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer c.SDL_DestroyWindow(screen);

    const renderer = c.SDL_CreateRenderer(screen, null) orelse {
        c.SDL_Log("Unable to create renderer: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer c.SDL_DestroyRenderer(renderer);

    const zig_bmp = @embedFile("zig.bmp");
    const rw = c.SDL_IOFromConstMem(zig_bmp, zig_bmp.len) orelse {
        c.SDL_Log("Unable to create RWFromConstMem: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer std.debug.assert(c.SDL_CloseIO(rw) == true);

    const zig_surface = c.SDL_LoadBMP_IO(rw, false) orelse {
        c.SDL_Log("Unable to load bmp: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer c.SDL_DestroySurface(zig_surface);

    const zig_texture = c.SDL_CreateTextureFromSurface(renderer, zig_surface) orelse {
        c.SDL_Log("Unable to create texture from surface: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer c.SDL_DestroyTexture(zig_texture);

    var quit = false;
    while (!quit) {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event)) {
            switch (event.type) {
                c.SDL_EVENT_QUIT => {
                    quit = true;
                },
                else => {},
            }
        }

        _ = c.SDL_RenderClear(renderer);
        _ = c.SDL_RenderTexture(renderer, zig_texture, null, null);
        _ = c.SDL_RenderPresent(renderer);

        c.SDL_Delay(20);
    }
}
