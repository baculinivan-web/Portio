package com.example.calcal.ui.detail

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.calcal.data.repository.FoodRepository
import com.example.calcal.domain.model.FoodItem
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class FoodItemDetailViewModel @Inject constructor(
    private val repository: FoodRepository
) : ViewModel() {

    fun getItem(id: String): Flow<FoodItem?> =
        repository.getAllItems().map { list -> list.find { it.id == id } }

    fun save(item: FoodItem) {
        viewModelScope.launch { repository.updateItem(item) }
    }

    fun delete(item: FoodItem) {
        viewModelScope.launch { repository.deleteItem(item) }
    }
}
