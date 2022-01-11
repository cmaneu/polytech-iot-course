using Microsoft.Azure.Devices.Client;
using System.Text;
using System.Text.Json;

Console.WriteLine("IoT Device Simulation");

// Variables
// string ConnectionString = "{Your device connection string here}";
string ConnectionString = "HostName=hub-iot-workshop.azure-devices.net;DeviceId=device-pedro;SharedAccessKey=g0552p0S5c2YMS4pS8LYZPF6Kzu8N2Dk5LwgXEsdFUM=";

// Setup IoT Client
var deviceClient = DeviceClient.CreateFromConnectionString(ConnectionString, TransportType.Mqtt);

// Send messages
double minTemperature = 20;
double minHumidity = 60;
var rand = new Random();

for (int i = 0; i < 10; i++)
{
    double currentTemperature = minTemperature + rand.NextDouble() * 15;
    double currentHumidity = minHumidity + rand.NextDouble() * 20;

    // Create JSON message
    string messageBody = JsonSerializer.Serialize(
        new
        {
            temperature = currentTemperature,
            humidity = currentHumidity,
            ts = DateTime.Now.ToString("G")
        });
        
    using var message = new Message(Encoding.ASCII.GetBytes(messageBody))
    {
        ContentType = "application/json",
        ContentEncoding = "utf-8",
    };

    // Add a custom application property to the message.
    // An IoT hub can filter on these properties without access to the message body.
    message.Properties.Add("temperatureAlert", (currentTemperature > 30) ? "true" : "false");

    // Send the telemetry message
    await deviceClient.SendEventAsync(message);
    Console.WriteLine($"{DateTime.Now} > Sending message: {messageBody}");

    await Task.Delay(1000);
}

// Clear resources
await deviceClient.CloseAsync();
Console.WriteLine("End of simulation");