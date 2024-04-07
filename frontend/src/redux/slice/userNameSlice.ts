import { createSlice } from "@reduxjs/toolkit";
import { PersistPartial } from 'redux-persist';

export interface UserNameState {
  name: string;
}

const initialState: UserNameState = {
  name: "",
};

const userNameSlice = createSlice<UserNameState & PersistPartial, any>({
  name: "userName",
  initialState,
  reducers: {
    changeUserName(state: any, action: { payload: string }) {
      state.name = action.payload;
    },
  },
});

export const { changeUserName } = userNameSlice.actions;
export const userNameReducer = userNameSlice.reducer;