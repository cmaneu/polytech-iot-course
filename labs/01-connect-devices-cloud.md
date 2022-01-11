# Lab 1: Connect Devices to a Cloud Gateway


## Objective

In this module, you'll learn how to: 
- Send messages from a simulated device (and explore client SDKs)
- [Deploy a Cloud Gateway](#Create-a-Cloud-Gateway-and-register-devices)
- Register a new device
- See how to watch for messages sent from a specific device

## Create a simulated device

First, we'll write device code that send messages to our Cloud Gateway (Azure IoT hub). For this first step, you'll use the Gateway (and credentials) setup by the workshop presenter. Later, you'll create your own Gateway and reuse the code from that step.

To create this simulated device, you can use a wide array of languages, including C, Python, Node.js, Java and .NET. Microsoft is publishing an [official SDK](https://docs.microsoft.com/en-us/azure/iot-develop/quickstart-send-telemetry-iot-hub?toc=%2Fazure%2Fiot-hub%2Ftoc.json&bc=%2Fazure%2Fiot-hub%2Fbreadcrumb%2Ftoc.json&pivots=programming-language-nodejs) for all these languages.
  
If you're developing an IoT device without using one of these languages, you can still leverage other ways to connect to the Cloud Gateway: 

- Via the [REST API](https://docs.microsoft.com/en-us/rest/api/iothub/device)
- Via an open protocol like [MQTT](https://docs.microsoft.com/en-us/azure/iot-hub/iot-hub-mqtt-support) or AMQP

### Use C#/.NET with Azure IoT SDK

You can write the following code **for .NET 6** in the environment you like: 
- Visual Studio 2022 or Visual Studio for Mac
- Visual Studio Code with .NET 6 SDK
- Visual Studio Code / GitHub Codespaces and Remote Development Extensions
- [.NET Fiddle](https://dotnetfiddle.net/)
- Jupyter Notebook

1. Create a new .NET 6 project
2. Add the Nuget Package `Microsoft.Azure.Devices.Client`
3. Copy/paste the following code
4. At the top of the file, replace the connection string by your Connection string.
5. Execute the code, and check with the workshop presenter if your message was well-received.

```csharp
using Microsoft.Azure.Devices.Client;
using System.Text;
using System.Text.Json;

Console.WriteLine("IoT Device Simulation");

// Variables
string ConnectionString = "{Your device connection string here}";

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
```


### Use C#/.NET with MQTT

Package to include: MQTTnet.

[.NET Fiddle link](https://dotnetfiddle.net/GDz5W0)


```csharp
using System;
using System.Text;
using System.Threading;
using MQTTnet;
using MQTTnet.Client.Options;
using MQTTnet.Protocol;

					
Console.WriteLine("Hello World");
string IoTHubServer  = "hub-iot-workshop.azure-devices.net";
string ClientId = "device1";
string ClientSASKey = "%REPLACE_BY_YOUR_SASKEY%";
 
var options = new MqttClientOptionsBuilder()
	.WithWebSocketServer($"{IoTHubServer}:443/$iothub/websocket?iothub-no-client-cert=true")
	.WithTls()
	.WithClientId(ClientId)
	.WithCredentials($"{IoTHubServer}/{ClientId}/?api-version=2018-06-30", ClientSASKey)
	.WithCleanSession(true)
	.Build();

var factory = new MqttFactory();
var mqttClient = factory.CreateMqttClient();

var result = await mqttClient.ConnectAsync(options, CancellationToken.None);  

var topic = $"devices/{ClientId}/messages/events/$.ct=application%2Fjson&$.ce=utf-8";
var payload = Encoding.ASCII.GetBytes("Hello IoT Hub from dotnetfiddle");
var message = new MqttApplicationMessageBuilder()
	.WithTopic(topic)
	.WithPayload(payload)
	.WithAtLeastOnceQoS()
	.Build();

var publishResult = await mqttClient.PublishAsync(message, CancellationToken.None);
```




### JavaScript

I haven't written yet the sample for Node.JS, but these links should help you:
- https://docs.microsoft.com/en-us/azure/iot-develop/quickstart-send-telemetry-iot-hub?toc=%2Fazure%2Fiot-hub%2Ftoc.json&bc=%2Fazure%2Fiot-hub%2Fbreadcrumb%2Ftoc.json&pivots=programming-language-nodejs
- https://github.com/Azure/azure-iot-sdk-node/blob/main/device/samples/javascript/simple_sample_device.js
- https://github.com/Azure-Samples/azure-iot-samples-node/blob/master/iot-hub/Quickstarts/simulated-device/package.json


## <a name="create-cloud-gateway"></a> Create a Cloud Gateway and register devices

### Create an Azure IoT Hub

You have several ways to create an IoT Hub: 
- Via the [Azure Portal](https://portal.azure.com)
- Via the Azure CLI (you can go on [shell.azure.com](https://shell.azure.com) to get a remote shell with Azure CLI installed)
- Via Infrastructure as code

For this workshop, you could use a Free (F1) IoT Hub.

### Via Azure CLI

Execute the following code in a shell with Azure CLI installed and configured. (replace `{UniqueName}`)

> The first time you're using the CLI for Azure IoT, you'll need to run the following command.
> ```bash
> az extension add --name azure-iot
> ```

```bash
RESOURCE_GROUP_NAME='rg-iot-workshop'
IOTHUB_NAME='iot-{UniqueName}'
az group create --name $RESOURCE_GROUP_NAME --location eastus
az iot hub create --resource-group $RESOURCE_GROUP_NAME --sku F1 --name $IOTHUB_NAME
```

### Via Infrastructure as code

Execute the following command from `01-connect-devices-cloud/infrastructure directory`

```bash
az deployment sub create --name 'iot-deploy' --location westeurope --template-file main.bicep
```


### Add a device

You now need to register a new device in your IoT Hub. You can do so via the Azure CLI or from the portal. The code below create a new device and display the primary key.

```bash
az iot hub device-identity create --device-id simDevice --hub-name $IOTHUB_NAME
az iot hub device-identity show --device-id simDevice --hub-name $IOTHUB_NAME
```

### Modify your simulator device code

You can go back to your code and change the connection string to point to your new Azure IoT Hub. Ensure you change the three values: hostname, device name (or device ID), and key.


## Watch messages from a specific device

The simplest way to watch for specific device message is to use Azure IoT Hub.

```bash
az iot hub monitor-events --output table --hub-name $IOTHUB_NAME
```
## What's next?



### Some reading

https://docs.microsoft.com/learn/modules/manage-iot-devices/?wt.mc_id=academic-6241-chmaneu

https://docs.microsoft.com/learn/modules/remotely-monitor-devices-with-azure-iot-hub/?wt.mc_id=academic-6241-chmaneu

https://docs.microsoft.com/azure/iot-hub/iot-hub-raspberry-pi-kit-node-get-started?wt.mc_id=academic-6241-chmaneu