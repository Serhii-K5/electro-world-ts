import { createSlice, createAsyncThunk } from "@reduxjs/toolkit";
// import { RootState } from "../store" // Import RootState type
import axios from 'axios';

interface Product {
  id: number;
  code: string;
  name: string;
  memo?: string;
  price: number;
  oldPrice?: number;
  quantity: number;
  parentId: number;
  fullPath: string;
  photo?: string;
  alternatives?: string;
  related?: string;
  ordered?: number;
}

interface ProductsState {
  items: Product[];
  isLoading: boolean;
  error: string | null;
}

const initialState: ProductsState = {
  items: [],
  isLoading: false,
  error: null,
};

export const fetchProducts = createAsyncThunk<Product[]>(
  'products/fetchAll',
  async (_, thunkAPI) => {
    try {
      const response = await axios.get('/product');
      return response.data;
    } catch (e) {
      return thunkAPI.rejectWithValue(e.message);
    }
  }
);

const productSlice = createSlice({
  name: 'products',
  initialState,
  extraReducers: builder => {
    builder
      .addCase(fetchProducts.pending, handlePending)
      .addCase(fetchProducts.fulfilled, (state, action) => {
        state.isLoading = false;
        state.error = null;
        state.items = action.payload;
      })
      .addCase(fetchProducts.rejected, handleRejected);
  },
});

const handlePending = (state: ProductsState) => {
  state.isLoading = true;
};

const handleRejected = (state: ProductsState, action: any) => { // Update type if needed
  state.isLoading = false;
  state.error = action.payload;
};

export const productsReducer = productSlice.reducer;
// xcd
 