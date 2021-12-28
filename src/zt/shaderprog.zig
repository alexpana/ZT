const std = @import("std");
usingnamespace @import("gl");

const LOG_BUFFER_SIZE = 512;
var LOG_BUFFER: [LOG_BUFFER_SIZE]u8 = undefined;

fn checkShader(shader: c_uint) void {
    var status: c_uint = undefined;
    glGetShaderiv(
        shader,
        GL_COMPILE_STATUS,
        @ptrCast([*c]c_int, &status),
    );

    if (status != GL_TRUE) {
        @memset(&LOG_BUFFER, 0, LOG_BUFFER_SIZE);
        glGetShaderInfoLog(shader, LOG_BUFFER_SIZE, null, &LOG_BUFFER);
        std.log.err("Shader compilation error:\n{s}\n", .{&LOG_BUFFER});
    }
}

fn checkProgram(program: c_uint) void {
    var status: c_uint = undefined;
    glGetProgramiv(
        program,
        GL_LINK_STATUS,
        @ptrCast([*c]c_int, &status),
    );

    if (status != GL_TRUE) {
        @memset(&LOG_BUFFER, 0, LOG_BUFFER_SIZE);
        glGetProgramInfoLog(program, LOG_BUFFER_SIZE, null, &LOG_BUFFER);
        std.log.err("Shader linking error:\n{s}\n", .{&LOG_BUFFER});
    }
}

pub var currentShader: c_uint = 0;
pub const Shader = struct {
    id: c_uint = 0,
    dead: bool = true,

    pub fn from(shaderID: c_uint) @This() {
        return .{
            .id = shaderID,
        };
    }

    pub fn init(vert: [*:0]const u8, frag: [*:0]const u8) @This() {
        var self = @This(){};

        var vertId = glCreateShader(GL_VERTEX_SHADER);
        glShaderSource(vertId, 1, &vert, null);
        glCompileShader(vertId);
        checkShader(vertId);

        var fragId = glCreateShader(GL_FRAGMENT_SHADER);
        glShaderSource(fragId, 1, &frag, null);
        glCompileShader(fragId);
        checkShader(fragId);

        self.id = glCreateProgram();
        glAttachShader(self.id, vertId);
        glAttachShader(self.id, fragId);
        glLinkProgram(self.id);
        checkProgram(self.id);

        glDeleteShader(vertId);
        glDeleteShader(fragId);

        glUseProgram(currentShader);

        self.dead = false;

        return self;
    }
    pub fn deinit(self: *Shader) void {
        glDeleteProgram(self.id);
        self.dead = true;
    }

    pub fn bind(self: *Shader) void {
        if (currentShader == self.id) {
            return;
        }
        glUseProgram(self.id);
        currentShader = self.id;
    }
    pub fn unbind(self: *Shader) void {
        currentShader = 0;
        glUseProgram(0);
    }
};
