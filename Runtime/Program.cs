using System.Net;
using System.Net.WebSockets;
using System.Diagnostics;
using System.Text;
using System.Runtime.InteropServices;

const string Prefix = "http://127.0.0.1:17477/";

Console.Title = "Macro Online Runtime";

Console.WriteLine("========================================");
Console.WriteLine("          MACRO ONLINE RUNTIME");
Console.WriteLine("========================================");
Console.WriteLine();
Console.WriteLine("WEBSOCKET : ws://127.0.0.1:17477");
Console.WriteLine("ENGINE    : MacroForge V7.4");
Console.WriteLine("TRIGGER   : Physical RMB");
Console.WriteLine("SEQUENCE  : LMB -> RMB -> LMB -> Q -> Q");
Console.WriteLine();

var projectRoot = Directory.GetParent(AppContext.BaseDirectory)!
    .Parent!.Parent!.Parent!.Parent!.FullName;

var enginePath = Path.Combine(
    projectRoot,
    "Engine",
    "MacroForge.MacroCombat-v7.4.exe"
);

var webPath = Path.Combine(
    projectRoot,
    "Web",
    "index.html"
);

Console.WriteLine("[ENGINE PATH]");
Console.WriteLine(enginePath);
Console.WriteLine();

if (!File.Exists(enginePath))
{
    Console.WriteLine("[ENGINE ERROR] Engine V7.4 tidak ditemukan.");
    Console.ReadLine();
    return;
}

Process? engine;

try
{
    engine = Process.Start(new ProcessStartInfo
    {
        FileName = enginePath,
        WorkingDirectory = Path.GetDirectoryName(enginePath)!,
        UseShellExecute = false,
        CreateNoWindow = false
    });

    Console.WriteLine("[ENGINE STARTED]");
}
catch (Exception ex)
{
    Console.WriteLine("[ENGINE ERROR] " + ex.Message);
    Console.ReadLine();
    return;
}

using var listener = new HttpListener();
listener.Prefixes.Add(Prefix);

try
{
    listener.Start();
}
catch (Exception ex)
{
    Console.WriteLine("[WEB ERROR] " + ex.Message);
    Console.ReadLine();
    return;
}

Console.WriteLine("[RUNTIME READY]");
Console.WriteLine("[WEB] http://127.0.0.1:17477");
Console.WriteLine();

_ = Task.Run(async () =>
{
    await Task.Delay(1000);

    try
    {
        Process.Start(new ProcessStartInfo
        {
            FileName = "http://127.0.0.1:17477",
            UseShellExecute = true
        });
    }
    catch
    {
    }
});

while (true)
{
    HttpListenerContext context;

    try
    {
        context = await listener.GetContextAsync();
    }
    catch
    {
        break;
    }

    _ = Task.Run(async () =>
    {
        var request = context.Request;
        var response = context.Response;

        try
        {
            if (request.IsWebSocketRequest)
            {
                var wsContext = await context.AcceptWebSocketAsync(null);
                var ws = wsContext.WebSocket;

                var buffer = new byte[4096];

                while (ws.State == WebSocketState.Open)
                {
                    WebSocketReceiveResult result;

                    try
                    {
                        result = await ws.ReceiveAsync(
                            buffer,
                            CancellationToken.None
                        );
                    }
                    catch
                    {
                        break;
                    }

                    if (result.MessageType == WebSocketMessageType.Close)
                        break;

                    var message = Encoding.UTF8
                        .GetString(buffer, 0, result.Count)
                        .Trim()
                        .ToUpperInvariant();

                    Console.WriteLine("[WEB COMMAND] " + message);

                    if (message == "ENABLE")
                    {
                        Console.WriteLine("[INPUT] Sending F6...");
                        SendFunctionKey(0x40);
                        Console.WriteLine("[INPUT] F6 sent.");
                    }
                    else if (message == "DISABLE")
                    {
                        Console.WriteLine("[INPUT] Sending F7...");
                        SendFunctionKey(0x41);
                        Console.WriteLine("[INPUT] F7 sent.");
                    }

                    var reply = Encoding.UTF8.GetBytes(
                        "OK:" + message
                    );

                    try
                    {
                        await ws.SendAsync(
                            reply,
                            WebSocketMessageType.Text,
                            true,
                            CancellationToken.None
                        );
                    }
                    catch
                    {
                        break;
                    }
                }

                try
                {
                    await ws.CloseAsync(
                        WebSocketCloseStatus.NormalClosure,
                        "closed",
                        CancellationToken.None
                    );
                }
                catch
                {
                }

                return;
            }

            if (File.Exists(webPath))
            {
                var data = await File.ReadAllBytesAsync(webPath);

                response.ContentType = "text/html; charset=utf-8";
                response.ContentLength64 = data.Length;

                await response.OutputStream.WriteAsync(data);
            }
            else
            {
                var html = """
                <!DOCTYPE html>
                <html>
                <body>
                <h1>Macro Online</h1>
                <p>Web UI tidak ditemukan.</p>
                </body>
                </html>
                """;

                var data = Encoding.UTF8.GetBytes(html);

                response.ContentType = "text/html; charset=utf-8";
                response.ContentLength64 = data.Length;

                await response.OutputStream.WriteAsync(data);
            }
        }
        catch
        {
        }
        finally
        {
            try
            {
                response.Close();
            }
            catch
            {
            }
        }
    });
}

static void SendFunctionKey(ushort scanCode)
{
    var inputDown = new INPUT
    {
        type = 1,
        U = new InputUnion
        {
            ki = new KEYBDINPUT
            {
                wVk = 0,
                wScan = scanCode,
                dwFlags = 0x0008,
                time = 0,
                dwExtraInfo = UIntPtr.Zero
            }
        }
    };

    var inputUp = new INPUT
    {
        type = 1,
        U = new InputUnion
        {
            ki = new KEYBDINPUT
            {
                wVk = 0,
                wScan = scanCode,
                dwFlags = 0x0008 | 0x0002,
                time = 0,
                dwExtraInfo = UIntPtr.Zero
            }
        }
    };

    SendInput(1, new[] { inputDown }, Marshal.SizeOf<INPUT>());

    Thread.Sleep(150);

    SendInput(1, new[] { inputUp }, Marshal.SizeOf<INPUT>());

    Thread.Sleep(100);
}

[DllImport("user32.dll", SetLastError = true)]
static extern uint SendInput(
    uint nInputs,
    INPUT[] pInputs,
    int cbSize
);

[StructLayout(LayoutKind.Sequential)]
struct INPUT
{
    public uint type;
    public InputUnion U;
}

[StructLayout(LayoutKind.Explicit)]
struct InputUnion
{
    [FieldOffset(0)]
    public KEYBDINPUT ki;
}

[StructLayout(LayoutKind.Sequential)]
struct KEYBDINPUT
{
    public ushort wVk;
    public ushort wScan;
    public uint dwFlags;
    public uint time;
    public UIntPtr dwExtraInfo;
}
