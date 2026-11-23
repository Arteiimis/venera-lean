#ifndef RUNNER_D3D11_MULTITHREAD_PATCH_H_
#define RUNNER_D3D11_MULTITHREAD_PATCH_H_

namespace venera {

// Makes ANGLE's D3D11 device thread-safe before the engine renders its first
// frame. Flutter 3.50 dropped the global lock around eglSwapBuffers, so the
// raster thread presenting a frame and any other thread issuing D3D11 calls
// (texture upload during image decode, for example) can touch the same
// immediate context; on some drivers that ends in an access violation inside
// the driver's own worker thread. Upstream enables ID3D10Multithread on the
// device to serialize those calls; 3.50.1 predates that fix, so the runner
// applies it for itself until we upgrade to a Flutter that contains it.
void InstallD3D11MultithreadPatch();

}  // namespace venera

#endif  // RUNNER_D3D11_MULTITHREAD_PATCH_H_
