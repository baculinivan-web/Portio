package com.example.portio.ui.tracker

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowUpward
import androidx.compose.material.icons.filled.PhotoCamera
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@Composable
fun ChatInput(onSubmit: (String) -> Unit, onCameraClick: () -> Unit) {
    var text by remember { mutableStateOf("") }

    Surface(
        tonalElevation = 0.dp,
        color = MaterialTheme.colorScheme.surface
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 12.dp, vertical = 10.dp)
                .navigationBarsPadding(),
            verticalAlignment = Alignment.Bottom,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            // Camera button
            FilledTonalIconButton(
                onClick = onCameraClick,
                modifier = Modifier.size(52.dp),
                shape = CircleShape
            ) {
                Icon(Icons.Default.PhotoCamera, contentDescription = "Camera")
            }

            // Text field
            OutlinedTextField(
                value = text,
                onValueChange = { text = it },
                placeholder = { Text("What did you eat?") },
                modifier = Modifier.weight(1f),
                shape = RoundedCornerShape(24.dp),
                singleLine = true,
                colors = OutlinedTextFieldDefaults.colors(
                    unfocusedBorderColor = MaterialTheme.colorScheme.outline.copy(alpha = 0.3f),
                    focusedBorderColor = MaterialTheme.colorScheme.outline.copy(alpha = 0.6f),
                    unfocusedContainerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.4f),
                    focusedContainerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.4f)
                )
            )

            // Send button
            FilledIconButton(
                onClick = {
                    if (text.isNotBlank()) {
                        onSubmit(text.trim())
                        text = ""
                    }
                },
                modifier = Modifier.size(52.dp),
                shape = CircleShape,
                enabled = text.isNotBlank()
            ) {
                Icon(Icons.Default.ArrowUpward, contentDescription = "Send")
            }
        }
    }
}
