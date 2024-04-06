import { createSlice } from "@reduxjs/toolkit";

interface DirectoryPathItem {
  id?: number;
  cat_id: number; 
  cat_parentId: number; 
  cat_photo?: string;
}

export interface DirectoryPathState {
  items: DirectoryPathItem[],
}

const initialState: DirectoryPathState = {
  items: [],
};

const sliceDirectoryPath = createSlice<DirectoryPathState & PersistPartial, any>({
  name: 'directoryPath',
  initialState,
  reducers: {
    // addDirectoryPath(state, action) {
    //   // state.items.push(action.payload);
    // },
    changeDirectoryPath(state, action: { payload: DirectoryPathItem }) {
      const index = state.items.findIndex(item =>
        item.cat_id === action.payload.cat_parentId);
      
      index < 0 ? (state.items = []) : state.items.splice(index + 1);
      
      state.items.push(action.payload);
    },
    deleteDirectoryPath(state, action: { payload: number }) {
      const index = state.items.findIndex(item => item.id === action.payload);
      state.items.splice(index, 1);
    },
    deleteAllDirectoryPath(state) {
      // state.items = action.payload;
      state.items = [];
    },
  },
});

// export const { addDirectoryPath, changeDirectoryPath, deleteDirectoryPath, deleteAllDirectoryPath } = sliceDirectoryPath.actions;
export const { changeDirectoryPath, deleteDirectoryPath, deleteAllDirectoryPath } = sliceDirectoryPath.actions;
export const directoryPathReducer = sliceDirectoryPath.reducer;

