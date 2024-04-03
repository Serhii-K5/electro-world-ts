import { createSlice } from "@reduxjs/toolkit";

interface OrderItem {
  id: number; 
}

interface OrdersState {
  items: OrderItem[];
}

const initialState: OrdersState = {
  items: [],
};

const ordersSlice = createSlice({
  name: 'orders',
  initialState,
  reducers: {
    addOrders(state, action: { payload: OrderItem[] }) {
      state.items.push(...action.payload); 
    },
    deleteOrders(state, action: { payload: number }) {
      const index = state.items.findIndex(item => item.id === action.payload);
      state.items.splice(index, 1);
    },
    updateOrders(state, action: { payload: OrderItem }) {
      const index = state.items.findIndex(item => item.id === action.payload.id);
      if (index !== -1) {
        state.items.splice(index, 1, action.payload);
      }
    },
    deleteAllOrders(state) {
      state.items = [];
    },
  },
});

export const { addOrders, deleteOrders, updateOrders, deleteAllOrders } = ordersSlice.actions;
export const ordersReducer = ordersSlice.reducer;