import { createSlice } from "@reduxjs/toolkit";
import { PersistPartial } from 'redux-persist';

export interface CategoryState {
  category: number;
}

const initialState: CategoryState = {
  category: 0,
};

const sliceCategory = createSlice<CategoryState & PersistPartial, any>({
  name: 'categories',
  initialState,
  reducers: {
    changeCategory(state: any, action: { payload: number }) {
      state.category = +action.payload;
    },
  },
});

export const { changeCategory } = sliceCategory.actions;
export const categoriesReducer = sliceCategory.reducer;
