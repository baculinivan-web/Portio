package com.example.portio.data.remote

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class OFFSearchResult(
    val count: Int = 0,
    val page: Int = 1,
    val products: List<OFFProduct> = emptyList()
)

@Serializable
data class OFFProduct(
    val code: String = "",
    @SerialName("product_name") val productName: String? = null,
    val brands: String? = null,
    val quantity: String? = null,
    @SerialName("serving_size") val servingSize: String? = null,
    val nutriments: OFFNutriments? = null
)

@Serializable
data class OFFNutriments(
    @SerialName("energy-kcal_100g") val energyKcal100g: Double? = null,
    @SerialName("proteins_100g") val proteins100g: Double? = null,
    @SerialName("carbohydrates_100g") val carbohydrates100g: Double? = null,
    @SerialName("fat_100g") val fat100g: Double? = null
)
