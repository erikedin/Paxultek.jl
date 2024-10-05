# MIT License
#
# Copyright (c) 2024 Erik Edin
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

module Paxultek

using GLFW
using Distributed

struct VisualizerContext
    channel::RemoteChannel
    exitchannel::RemoteChannel
end

function stop(context::VisualizerContext)
    # TODO For now there is only one event, an exit event,
    # so it doesn't matter what value we send here.
    put!(context.channel, 1)
end

function handleevent(::VisualizerContext, window, ev)
    GLFW.SetWindowShouldClose(window, true)
end

function runvisualizer(context::VisualizerContext)
    # Create a window and its OpenGL context
    window = GLFW.CreateWindow(640, 480, "Paxultek")

    # Make the window's context current
    GLFW.MakeContextCurrent(window)

    # Loop until the user closes the window
    while !GLFW.WindowShouldClose(window)
        # Handle events from the user
        if isready(context.channel)
            # TODO Handle only one event per frame for now, but it should handle all
            ev = take!(context.channel)

            handleevent(context, window, ev)
        end

	    # Render here

	    # Swap front and back buffers
	    GLFW.SwapBuffers(window)

	    # Poll for and process events
	    GLFW.PollEvents()
    end

    GLFW.DestroyWindow(window)
end

function start()
    channel = RemoteChannel(() -> Channel{Int}(10))
    exitchannel = RemoteChannel(() -> Channel{Int}(10))
    context = VisualizerContext(channel, exitchannel)

    workerpid = Distributed.workers()[1]

    remote_do(runvisualizer, workerpid, context)

    context
end

end # module Paxultek