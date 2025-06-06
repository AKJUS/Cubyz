const std = @import("std");

const main = @import("main");
const graphics = main.graphics;
const draw = graphics.draw;
const Texture = graphics.Texture;
const network = main.network;
const Vec2f = main.vec.Vec2f;

const gui = @import("../gui.zig");
const GuiWindow = gui.GuiWindow;
const GuiComponent = gui.GuiComponent;

pub var window = GuiWindow{
	.relativePosition = .{
		.{.attachedToFrame = .{.selfAttachmentPoint = .upper, .otherAttachmentPoint = .upper}},
		.{.attachedToFrame = .{.selfAttachmentPoint = .upper, .otherAttachmentPoint = .upper}},
	},
	.contentSize = Vec2f{192, 128},
	.isHud = false,
	.showTitleBar = false,
	.hasBackground = false,
	.hideIfMouseIsGrabbed = false,
};

pub fn render() void {
	draw.setColor(0xffffffff);
	var y: f32 = 0;
	if(main.game.world != null) {
		if(main.server.world != null) {
			const userList = main.server.getUserListAndIncreaseRefCount(main.stackAllocator);
			defer main.server.freeUserListAndDecreaseRefCount(main.stackAllocator, userList);
			draw.print("Players Connected: {}", .{userList.len}, 0, y, 8, .left);
			y += 8;
		}
		const sent = network.Connection.packetsSent.load(.monotonic);
		const resent = network.Connection.packetsResent.load(.monotonic);
		const loss = @as(f64, @floatFromInt(resent))/@as(f64, @floatFromInt(sent))*100;
		draw.print("Packet loss: {d:.1}% ({}/{})", .{loss, resent, sent}, 0, y, 8, .left);
		y += 8;
		draw.print("Internal message overhead: {}kiB", .{network.Connection.internalMessageOverhead.load(.monotonic) >> 10}, 0, y, 8, .left);
		y += 8;
		draw.print("Internal header overhead: {}kiB", .{network.Connection.internalHeaderOverhead.load(.monotonic) >> 10}, 0, y, 8, .left);
		y += 8;
		draw.print("External header overhead: {}kiB", .{network.Connection.externalHeaderOverhead.load(.monotonic) >> 10}, 0, y, 8, .left);
		y += 8;
		inline for(@typeInfo(network.Protocols).@"struct".decls) |decl| {
			if(@TypeOf(@field(network.Protocols, decl.name)) == type) {
				const id = @field(network.Protocols, decl.name).id;
				draw.print("{s}: received {}kiB sent {}kiB", .{decl.name, network.Protocols.bytesReceived[id].load(.monotonic) >> 10, network.Protocols.bytesSent[id].load(.monotonic) >> 10}, 0, y, 8, .left);
				y += 8;
			}
		}
	}
	if(window.contentSize[1] != y) {
		window.contentSize[1] = y;
		window.updateWindowPosition();
	}
}
