// import { createSlice, createAsyncThunk } from "@reduxjs/toolkit";
// import { PersistPartial } from 'redux-persist';
// // import { RootState } from "../store";
// import axios from 'axios';

// export interface Product {
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

// export interface ProductsState {
//   items: Product[];
//   isLoading: boolean;
//   error: string | null;
// }

// const initialState: ProductsState = {
//   items: [],
//   isLoading: false,
//   error: null,
// };

// export const fetchProducts = createAsyncThunk<Product[]>(
//   'products/fetchAll',
//   async (_, thunkAPI) => {
//     try {
//       const response = await axios.get('/product');
//       return response.data;
//     } catch (e: any) {
//       return thunkAPI.rejectWithValue(e.message);
//     }
//   }
//   );
  
//   // const productSlice = createSlice<ProductsState & PersistPartial, any>({
//   //   // ... your slice definition
//   // });
// // const productSlice = createSlice({
// const productSlice = createSlice<ProductsState & PersistPartial, any>({
//   name: 'products',
//   initialState,
//   reducers: {
//     // Add your product-specific reducers here (e.g., addProduct, removeProduct, updateProduct)
//   },
//   extraReducers: builder => {
//     builder
//       .addCase(fetchProducts.pending, handlePending)
//       .addCase(fetchProducts.fulfilled, (state, action) => {
//         state.isLoading = false;
//         state.error = null;
//         state.items = action.payload;
//       })
//       .addCase(fetchProducts.rejected, handleRejected);
//   },
// });

// const handlePending = (state: ProductsState) => {
//   state.isLoading = true;
// };

// const handleRejected = (state: ProductsState, action: any) => {
//   state.isLoading = false;
//   state.error = action.payload;
// };

// export const productsReducer = productSlice.reducer;
