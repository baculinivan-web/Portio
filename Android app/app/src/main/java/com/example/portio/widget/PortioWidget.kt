package com.example.portio.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.*
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.layout.*
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.example.portio.MainActivity
import com.example.portio.data.local.AppDatabase
import kotlinx.coroutines.flow.first
import java.util.Calendar

// Design tokens
private val BgDark = Color(0xFF1A1A2E)
private val AccentGreen = Color(0xFF4CAF50)
private val AccentOrange = Color(0xFFFF9800)
private val AccentBlue = Color(0xFF2196F3)
private val TextPrimary = Color(0xFFFFFFFF)
private val TextSecondary = Color(0xFFB0BEC5)
private val TrackBg = Color(0xFF2A2A4A)

class PortioWidget : GlanceAppWidget() {

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val db = AppDatabase.getInstance(context)
        val dao = db.foodItemDao()

        val cal = Calendar.getInstance()
        cal.set(Calendar.HOUR_OF_DAY, 0)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
        val start = cal.timeInMillis
        val end = start + 24 * 60 * 60 * 1000L

        val items = dao.getItemsForDay(start, end).first()
        val totalCalories = items.sumOf { it.calories }.toInt()
        val totalProtein = items.sumOf { it.protein }.toInt()
        val totalCarbs = items.sumOf { it.carbs }.toInt()
        val totalFat = items.sumOf { it.fat }.toInt()

        // Default daily goal — could be read from DataStore later
        val calorieGoal = 2000

        provideContent {
            WidgetContent(
                calories = totalCalories,
                calorieGoal = calorieGoal,
                protein = totalProtein,
                carbs = totalCarbs,
                fat = totalFat,
                context = context
            )
        }
    }
}

@Composable
private fun WidgetContent(
    calories: Int,
    calorieGoal: Int,
    protein: Int,
    carbs: Int,
    fat: Int,
    context: Context
) {
    val progress = (calories.toFloat() / calorieGoal).coerceIn(0f, 1f)
    val remaining = (calorieGoal - calories).coerceAtLeast(0)

    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(ColorProvider(BgDark))
            .cornerRadius(20)
            .clickable(actionStartActivity<MainActivity>())
            .padding(16.dp)
    ) {
        Column(
            modifier = GlanceModifier.fillMaxSize(),
            verticalAlignment = Alignment.Vertical.Top
        ) {
            // Header row
            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                verticalAlignment = Alignment.Vertical.CenterVertically
            ) {
                Text(
                    text = "🔥 Portio",
                    style = TextStyle(
                        color = ColorProvider(TextPrimary),
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold
                    )
                )
                Spacer(modifier = GlanceModifier.defaultWeight())
                Text(
                    text = "сегодня",
                    style = TextStyle(
                        color = ColorProvider(TextSecondary),
                        fontSize = 11.sp
                    )
                )
            }

            Spacer(modifier = GlanceModifier.height(10.dp))

            // Calorie count + remaining
            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                verticalAlignment = Alignment.Vertical.Bottom
            ) {
                Text(
                    text = "$calories",
                    style = TextStyle(
                        color = ColorProvider(TextPrimary),
                        fontSize = 32.sp,
                        fontWeight = FontWeight.Bold
                    )
                )
                Spacer(modifier = GlanceModifier.width(4.dp))
                Text(
                    text = "/ $calorieGoal ккал",
                    style = TextStyle(
                        color = ColorProvider(TextSecondary),
                        fontSize = 13.sp
                    ),
                    modifier = GlanceModifier.padding(bottom = 4.dp)
                )
            }

            Spacer(modifier = GlanceModifier.height(6.dp))

            // Progress bar — 10 segments
            val barColor = when {
                progress >= 1f -> AccentOrange
                progress >= 0.75f -> AccentGreen
                else -> AccentBlue
            }
            val filledSegments = (progress * 10).toInt().coerceIn(0, 10)
            Row(
                modifier = GlanceModifier.fillMaxWidth().height(6.dp)
            ) {
                repeat(10) { i ->
                    Box(
                        modifier = GlanceModifier
                            .defaultWeight()
                            .fillMaxHeight()
                            .background(ColorProvider(if (i < filledSegments) barColor else TrackBg))
                            .cornerRadius(3)
                    ) {}
                    if (i < 9) Spacer(modifier = GlanceModifier.width(2.dp))
                }
            }

            Spacer(modifier = GlanceModifier.height(4.dp))

            Text(
                text = if (remaining > 0) "осталось $remaining ккал" else "цель достигнута 🎉",
                style = TextStyle(
                    color = ColorProvider(TextSecondary),
                    fontSize = 11.sp
                )
            )

            Spacer(modifier = GlanceModifier.height(10.dp))

            // Macros row
            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                horizontalAlignment = Alignment.Horizontal.Start
            ) {
                MacroChip(label = "Б", value = "${protein}г", color = AccentBlue)
                Spacer(modifier = GlanceModifier.width(6.dp))
                MacroChip(label = "У", value = "${carbs}г", color = AccentGreen)
                Spacer(modifier = GlanceModifier.width(6.dp))
                MacroChip(label = "Ж", value = "${fat}г", color = AccentOrange)
            }
        }
    }
}

@Composable
private fun MacroChip(label: String, value: String, color: Color) {
    Box(
        modifier = GlanceModifier
            .background(ColorProvider(color.copy(alpha = 0.18f)))
            .cornerRadius(10)
            .padding(horizontal = 10.dp, vertical = 5.dp)
    ) {
        Row(verticalAlignment = Alignment.Vertical.CenterVertically) {
            Text(
                text = label,
                style = TextStyle(
                    color = ColorProvider(color),
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold
                )
            )
            Spacer(modifier = GlanceModifier.width(3.dp))
            Text(
                text = value,
                style = TextStyle(
                    color = ColorProvider(TextPrimary),
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Medium
                )
            )
        }
    }
}

class PortioWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = PortioWidget()
}
