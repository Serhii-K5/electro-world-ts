import { createSlice } from "@reduxjs/toolkit";

export interface CategoryState {
  category: number;
}

const initialState: CategoryState = {
  category: 0,
};

const sliceCategory = createSlice({
  name: 'categories',
  initialState,
  reducers: {
    changeCategory(state, action: { payload: number }) {
      state.category = +action.payload;
    },
  },
});

export const { changeCategory } = sliceCategory.actions;
export const categoriesReducer = sliceCategory.reducer;
