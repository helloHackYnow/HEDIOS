# The hedios protocol

## Disclaimer 

This repo is the result of a bit less than a week of work. I am aware of the incompleteness of this protocol, but it's still in is infant stage.

I will happily accept any form of suggestion to this project, on which I can only work on my spare time.

You can find the associated cpp client [here](https://github.com/helloHackYnow/HEDIOS-client)

## Introduction

The hedios protocol is a small uart based protocol I'm working on which allows simple bidirectionnal communication between a fpga and a computer. The main goal is to developp a plug and play set tools to streamline the debuging process of a fpga design.

The protocol implements sending labeled value from the fpga to the computer, sending labeled values from the computer to the fpga, reseting the fpga from the computer, trigering action on the fpga from the computer.

Around this protocol, I'm building a verilog module called an HediosEndpoint, which will be when complete a plug and play module that take of all the serial transmissions and processing of the packets.

## Under the hood

### Hedios Packet

A hedios packet follows the following structure : 

| Command  | Data[0] |  Data[1] |  Data[2] |  Data[3] |
| -------- | ------- |  ------- |  ------- |  ------- |
| First byte   |      |          |                |  Last byte |
| | Least important data byte | | | Most important data byte |

It's important to note that the packet are send following the little endian convention.

### Hedios Slots

A hedios slot is a 32 input on the endpoint, which can be connected, for example, to a register in the fpga's logic. The slot count is a parameter of the enpoint intance. The client can request the slot count of the endpoint, an update of a specific slot, or an update of all the slots.

### Hedios Actions

While hedios slots implement endpoint to client communication, hedios actions allow for the opposite.

An hedios action is a 1 bit output of the hedios endpoint. It can be set to 1 on request of the client, and set to low by the fpga's logic.
For example, the client could ask the fpga to start a task by setting the coresponding action to 1. Then, when the fpga is able to start the task, it can set the action to 0 in order to protect against trigering multiple times the same task.

There are to kind of Hedios Action : VAR_ACTION and VARLESS action.

VARLESS_ACTION are fairly straight-forward : the client can send a packet containing the id of the action, which when received set to 1 to corresponding enpoint output. There are 64 possible VARLESS_ACTION.

VAR_ACTION are more complex : in addition to the 1 bit endpoint output, there is an associated 32 bit ouput containing the argument of the action. This can allow, for example, to set a register in the fpga logic from the client. There are 64 possible VARLESS_ACTION

### Hedios command

| Commands sent by the fpga | | | |
| ------------------------- | -- | -- | -- |
| Name              | Command byte | Description | Implentation status |
| HDC_PING          | 0b00000001 | Simple ping sent to the client. The fpga will expect a HTC_PONG awnser.  | Not implemented |
| HDC_DONE          | 0b00000010 | Signal to the client the endpoint has ended its task.                    | Not implemented |
| HDC_PONG          | 0b00000011 | Endpoint's anwser when receiving HTC_PING.                               | Implemented |
| HDC_SLOT_COUNT    | 0b00000101 | Data[0] of the packet contains the count of opened slot on the endpoint. | Implemented |
| HDC_ACTION_COUNT  | 0b00000110 | Data[0] contains VAR_ACTION_COUNT, Data[1] contains VARLESS_ACTION_COUNT.| Implemented |
| HDC_INVALID_SLOT  | 0b00001001 | Endpoint's awnser if the asked slot to update is invalid / out of bound. | Implemented |
| HDC_UNKNOWN_COMMAND | 0b00001100 | Endpoint's awnser if the last packet sent by the client if invalid.        | Implemented |
| HDC_UPDATE_VALUE  | 0b1xxxxxxx | The 7 first bits (x) are the id of the slot, Data contains the value of the slot | Implemented |  


| Commands sent by the client | | | |
| ------------------------- | -- | -- | -- |
| Name              | Command byte | Description | Implentation status |
| HTD_PING          | 0b00000001   | Simple ping sent to the endpoint. The client expect a HDC_PONG awnser. | Implemented |
| HTD_UPDATE_SLOT   | 0b00000010   | Request an update for a slot. The slot id is stored in Data[0].        | Implemented |
| HTD_UPDATE_ALL_SLOTS | 0b00000011| Request an update for all the opened slots.                            | Implemented |
| HTD_ASK_SLOT_COUNT| 0b00000100   | Request a HDC_SLOT_COUNT awnser.                                       | Implemented |
| HTD_ASK_ACTION_COUNT | 0b00000101| Request a HDC_ACTION_COUNT awnser.                                     | Implemented |
| HTD_SEND_ACTION   | 0b1Vxxxxxx   | Send a action. If *V* is 1, it's a VAR_ACTION, else it's a VARLESS_ACTION. The last 6 bits are the id of the action.| Implemented |

## How to use it 

Simply copy the content of the __verilog__ directory in the source folder of your project. If you are using Vivado, don't forget to add the copied files to the design sources of the project.

You can then instance the HediosEndpoint wherever you need it.

### Inputs of the endpoint

| Name                      | Size (bits)               | Description                                               |
| ----                      | ----                      | -----------                                               |
| clk                       | 1                         | Clock                                                     |
| rst                       | 1                         | Reset signal                                              |
| rx_line                   | 1                         | Used for the uart reception (client to fpga)              |
| hedios_slots              | 32 * slot_count           | Are what is sent to the client                            |


### Outputs of the endpoint

| Name                      | Size (bits)               | Description                                               |
| ----                      | ----                      | -----------                                               |
| tx_line                   | 1                         | Used for uart transmission (fpga to client)               |
| var_action_out            | 1 * var_action_count      | var_action_out[i] is set to high for a single tick when the client sends the corresponding var action to the fpga |
| var_action_parameters     | 32 * var_action_count     | var_action_parameters[i] contains the parameter corresponding to the associated var_action |  
| varless_action_out        | 1 * varless_action_count  | Same as for var_action_out                                |
| rst_device                | 1                         | Is set to high when the client sends the rst command. Can be connected to the main reset line to allows for resetting the fpga from the client |