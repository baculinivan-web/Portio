package com.example.calcal.ui.camera

import android.Manifest
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Image
import androidx.compose.material.icons.filled.PhotoCamera
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.isGranted
import com.google.accompanist.permissions.rememberPermissionState
import com.google.accompanist.permissions.shouldShowRationale
import java.io.ByteArrayOutputStream

@OptIn(ExperimentalPermissionsApi::class)
@Composable
fun CameraScreen(onPhotoTaken: (ByteArray) -> Unit, onDismiss: () -> Unit) {
    val context = LocalContext.current
    val cameraPermission = rememberPermissionState(Manifest.permission.CAMERA)

    // Android 13+ uses Photo Picker (no permission needed)
    // Android 9-12 uses GetContent with READ_EXTERNAL_STORAGE
    val pickMediaLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.PickVisualMedia()
    ) { uri: Uri? ->
        uri?.let {
            val bytes = context.contentResolver.openInputStream(it)?.readBytes()
            if (bytes != null) onPhotoTaken(bytes)
        }
    }

    // Fallback for Android < 13
    val getContentLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        uri?.let {
            val bytes = context.contentResolver.openInputStream(it)?.readBytes()
            if (bytes != null) onPhotoTaken(bytes)
        }
    }

    val storagePermission = rememberPermissionState(Manifest.permission.READ_EXTERNAL_STORAGE)

    fun openGallery() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // Android 13+ — Photo Picker, no permission needed
            pickMediaLauncher.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))
        } else if (storagePermission.status.isGranted) {
            getContentLauncher.launch("image/*")
        } else {
            storagePermission.launchPermissionRequest()
        }
    }

    LaunchedEffect(Unit) {
        if (!cameraPermission.status.isGranted) {
            cameraPermission.launchPermissionRequest()
        }
    }

    // If storage permission just granted, open gallery
    LaunchedEffect(storagePermission.status.isGranted) {
        if (storagePermission.status.isGranted && Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            // Don't auto-open, user will tap the button again
        }
    }

    when {
        cameraPermission.status.isGranted -> {
            CameraPreviewScreen(
                onPhotoTaken = onPhotoTaken,
                onDismiss = onDismiss,
                onOpenGallery = { openGallery() }
            )
        }
        cameraPermission.status.shouldShowRationale -> {
            PermissionRationaleScreen(
                onRequest = { cameraPermission.launchPermissionRequest() },
                onDismiss = onDismiss,
                onOpenGallery = { openGallery() }
            )
        }
        else -> {
            PermissionDeniedScreen(
                onDismiss = onDismiss,
                onOpenGallery = { openGallery() }
            )
        }
    }
}

@Composable
private fun CameraPreviewScreen(onPhotoTaken: (ByteArray) -> Unit, onDismiss: () -> Unit, onOpenGallery: () -> Unit) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    var imageCapture: ImageCapture? by remember { mutableStateOf(null) }
    var capturedBytes: ByteArray? by remember { mutableStateOf(null) }

    if (capturedBytes != null) {
        PhotoPreviewView(
            imageBytes = capturedBytes!!,
            onConfirm = { onPhotoTaken(capturedBytes!!) },
            onRetake = { capturedBytes = null }
        )
        return
    }

    Box(Modifier.fillMaxSize()) {
        AndroidView(
            factory = { ctx ->
                val previewView = PreviewView(ctx).apply {
                    implementationMode = PreviewView.ImplementationMode.COMPATIBLE
                }
                val cameraProviderFuture = ProcessCameraProvider.getInstance(ctx)
                cameraProviderFuture.addListener({
                    val cameraProvider = cameraProviderFuture.get()
                    val preview = Preview.Builder().build().also {
                        it.surfaceProvider = previewView.surfaceProvider
                    }
                    val capture = ImageCapture.Builder()
                        .setCaptureMode(ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY)
                        .build()
                    imageCapture = capture
                    try {
                        cameraProvider.unbindAll()
                        cameraProvider.bindToLifecycle(
                            lifecycleOwner,
                            CameraSelector.DEFAULT_BACK_CAMERA,
                            preview,
                            capture
                        )
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }, ContextCompat.getMainExecutor(ctx))
                previewView
            },
            modifier = Modifier.fillMaxSize()
        )

        // Close button top-right
        IconButton(
            onClick = onDismiss,
            modifier = Modifier.align(Alignment.TopEnd).padding(16.dp)
        ) {
            Icon(Icons.Default.Close, contentDescription = "Close", tint = Color.White)
        }

        // Bottom controls: gallery | shutter | close placeholder
        Row(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .padding(bottom = 48.dp, start = 32.dp, end = 32.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Gallery button
            IconButton(onClick = onOpenGallery, modifier = Modifier.size(56.dp)) {
                Icon(Icons.Default.Image, contentDescription = "Gallery",
                    tint = Color.White, modifier = Modifier.size(32.dp))
            }

            // Shutter button
            IconButton(
                onClick = {
                    val capture = imageCapture ?: return@IconButton
                    capture.takePicture(
                        ContextCompat.getMainExecutor(context),
                        object : ImageCapture.OnImageCapturedCallback() {
                            override fun onCaptureSuccess(image: ImageProxy) {
                                val buffer = image.planes[0].buffer
                                val bytes = ByteArray(buffer.remaining()).also { buffer.get(it) }
                                val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
                                val out = ByteArrayOutputStream()
                                bitmap?.compress(Bitmap.CompressFormat.JPEG, 80, out)
                                capturedBytes = out.toByteArray()
                                image.close()
                            }
                            override fun onError(e: ImageCaptureException) { e.printStackTrace() }
                        }
                    )
                },
                modifier = Modifier.size(80.dp)
            ) {
                Icon(Icons.Default.PhotoCamera, contentDescription = "Take photo",
                    tint = Color.White, modifier = Modifier.size(52.dp))
            }

            // Spacer to balance layout
            Spacer(Modifier.size(56.dp))
        }
    }
}

@Composable
fun PhotoPreviewView(imageBytes: ByteArray, onConfirm: () -> Unit, onRetake: () -> Unit) {
    Column(Modifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally) {
        Box(modifier = Modifier.weight(1f).fillMaxWidth()) {
            Text("Photo captured — ready to analyze",
                modifier = Modifier.align(Alignment.Center),
                color = Color.White)
        }
        Row(
            Modifier.fillMaxWidth().padding(16.dp),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            OutlinedButton(onClick = onRetake) { Text("Retake") }
            Button(onClick = onConfirm) { Text("Use Photo") }
        }
    }
}

@Composable
private fun PermissionRationaleScreen(onRequest: () -> Unit, onDismiss: () -> Unit, onOpenGallery: () -> Unit) {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text("Camera permission is needed to take food photos")
            Button(onClick = onRequest) { Text("Grant Camera Permission") }
            OutlinedButton(onClick = onOpenGallery) {
                Icon(Icons.Default.Image, contentDescription = null, modifier = Modifier.size(16.dp))
                Spacer(Modifier.width(6.dp))
                Text("Choose from Gallery")
            }
            TextButton(onClick = onDismiss) { Text("Cancel") }
        }
    }
}

@Composable
private fun PermissionDeniedScreen(onDismiss: () -> Unit, onOpenGallery: () -> Unit) {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text("Camera permission denied. Enable it in Settings.")
            OutlinedButton(onClick = onOpenGallery) {
                Icon(Icons.Default.Image, contentDescription = null, modifier = Modifier.size(16.dp))
                Spacer(Modifier.width(6.dp))
                Text("Choose from Gallery")
            }
            TextButton(onClick = onDismiss) { Text("Go Back") }
        }
    }
}
