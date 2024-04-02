import { createSlice } from "@reduxjs/toolkit";

interface DirectoryPath {
  // Define the structure of a product object
  // directoryPath: number;
}

interface DirectoryPathState {
  items: DirectoryPath[],
}

const initialState: DirectoryPathState = {
  items: [],
};

const sliceDirectoryPath = createSlice({
  name: 'directoryPath',
  initialState,
  reducers: {
    // addDirectoryPath(state, action) {
    //   // state.items.push(action.payload);
    // },
    changeDirectoryPath(state, action) {
      const index = state.items.findIndex(item =>
        item.cat_id === action.payload.cat_parentId);
      
      index < 0 ? (state.items = []) : state.items.splice(index + 1);
      
      state.items.push(action.payload);
    },
    deleteDirectoryPath(state, action) {
      const index = state.items.findIndex(item => item.id === action.payload);
      state.items.splice(index, 1);
    },
    deleteAllDirectoryPath(state, action) {
      // state.items = action.payload;
      state.items = [];
    },
  },
});

// export const { addDirectoryPath, changeDirectoryPath, deleteDirectoryPath, deleteAllDirectoryPath } = sliceDirectoryPath.actions;
export const directoryPathReducer = sliceDirectoryPath.reducer;
