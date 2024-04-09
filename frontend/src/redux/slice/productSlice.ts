
import { createReducer, PayloadAction } from '@reduxjs/toolkit';
import { fetchProducts } from '../operations'; // Assuming fetchProducts returns an array of Products
import { Product } from "../../constantValues/constants";
// interface Product {
//   id: number;
//   code: string;
//   name: string;
//   memo?: string;
//   price: number;
//   oldPrice?: number;
//   quantity: number;
//   parentId: number;
//   fullPath: string;
//   photo?: string;
//   alternatives?: string;
//   related?: string;
//   ordered?: number;
// }

export interface ProductsState {
  items: Product[];
  isLoading: boolean;
  error: string | null;
}

const initialState: ProductsState = {
  items: [],
  isLoading: false,
  error: null,
};

const handlePending = (state: ProductsState) => {
  state.isLoading = true;
};

const handleFulfilled = (state: ProductsState, action: PayloadAction<Product[]>) => {
  state.isLoading = false;
  state.error = null;
  state.items = action.payload;
};

const handleRejected = (state: ProductsState, action: PayloadAction<string>) => {
  state.isLoading = false;
  state.error = action.payload;
};

export const productsReducer = createReducer(
  initialState,
  {
    [fetchProducts.pending.type]: handlePending,
    [fetchProducts.fulfilled.type]: handleFulfilled,
    [fetchProducts.rejected.type]: handleRejected,
  }
);
