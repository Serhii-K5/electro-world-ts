import { createSlice } from "@reduxjs/toolkit";

interface FilterValue {
  // Define the type of the filter value based on your logic
  // It could be a string, number, or an object with specific properties
  key: string;
  // value?: string | number ;
  value?: any;
}

interface FilterItem {
  key: string;
  value: FilterValue[];
}

export interface FiltersState {
  items: FilterItem[];
}

const initialState: FiltersState = {
  items: [],
};

const sliceFilters = createSlice({
  name: 'filters',
  initialState,
  reducers: {    
    addFilters(state, action: { payload: { key: string; value: FilterValue } }) {
      const { key, value } = action.payload;
      // Проверяем, существует ли уже объект с таким ключом
      const existingFilterIndex = state.items.findIndex(filter => filter.key === key);

      if (existingFilterIndex !== -1) {
        // Если ключ существует, обновляем значение
        const existingFilterValueIndex = state.items[existingFilterIndex].value.findIndex(filter => filter === value);
        if (existingFilterValueIndex === -1) {          
          state.items[existingFilterIndex].value.push(value);
        } else {
          // state.items[existingFilterIndex].splice(0, 1, value);
          state.items[existingFilterIndex].value[existingFilterValueIndex] = value;
        }
      } else {
        // Если ключа нет, добавляем новый объект
        // state.items.push({ key: key, value: [value] });
        state.items.push({ key, value: [value] });
      }
    },
    changeFilters(state, action: { payload: { key: string; value: FilterValue | FilterValue[] } }) {
      const { key, value } = action.payload;
      
      // const searchKey = (currentArray: FilterItem[], currentKey: string) => {
      const searchKey = (currentArray: any[], currentKey: string) => {
        const existingFilterIndex = currentArray.findIndex(filter => filter.key === currentKey);
        if (existingFilterIndex !== -1) { 
          // Если ключ существует, обновляем значение
          if (typeof value === 'object' && !(value instanceof Array) && 'key' in value) { 
            // Если значение является объектом и это не массив, повторно вызывается функция
            // searchKey(value, state.items[existingFilterIndex].value.key);
            searchKey(value as any, state.items[existingFilterIndex].key);
            // searchKey(value as object, (value as object).key);
            searchKey(value as any, key);
          } else if (value instanceof Array && Number.isFinite(value[0])) {
            currentArray[existingFilterIndex].value = [value];
          } else {
            // Проверка на наличие значения
            currentArray[existingFilterIndex].value ?
              currentArray[existingFilterIndex].value.push(value)
              : currentArray[existingFilterIndex].value = [value];
          }
        } else {
          // Если ключа нет, добавляем новый объект
          // curentArray.push({ key: key, value: [value] }); 
          currentArray.push({ key, value: Array.isArray(value) ? value : [value] });
        }
      }

      searchKey(state.items, key);
    },
    deleteFilters(state, action: { payload: { key: string; value?: FilterValue } }) {
      // const { key } = action.payload;
      const { key, value } = action.payload;

      const searchKey = (currentArray: FilterItem[], currentKey: string) => {
        const existingFilterIndex = currentArray.findIndex(filter => filter.key === currentKey);
        if (existingFilterIndex !== -1) { 
          // Если ключ существует, обновляем значение
          // if (!value || value === "") {
          if (!value) {
            currentArray.splice(existingFilterIndex, 1);
          } else if (typeof value === 'object' && (value instanceof Array)) { 
            // Если значение является объектом и это не массив, повторно вызывается функция
            // searchKey(value.value, value.key);
            searchKey(value as any, key);
          } else if (!(value instanceof Array && Number.isFinite(value[0]))) {
            const existingFilterValueIndex = currentArray[existingFilterIndex].value.findIndex(filter => filter === value);
            if (existingFilterValueIndex !== -1 && currentArray[existingFilterIndex].value.length > 1) {
              currentArray[existingFilterIndex].value.splice(existingFilterValueIndex, 1);
            } else {
              currentArray.splice(existingFilterIndex, 1);
            };
          }
        }
      }

      searchKey(state.items, key);
    },
  },
});

export const { addFilters, changeFilters, deleteFilters } = sliceFilters.actions;
export const filtersReducer = sliceFilters.reducer;

// -------------------------
// import { createSlice } from "@reduxjs/toolkit";

// interface FilterValue {
//   // Define the type of the filter value based on your logic
//   // It could be a string, number, or an object with specific properties
// }

// interface FilterItem {
//   key: string;
//   value: FilterValue[];
// }

// interface FiltersState {
//   items: FilterItem[];
// }

// const initialState: FiltersState = {
//   items: [],
// };

// const filtersSlice = createSlice({
//   name: 'filters',
//   initialState,
//   reducers: {
//     addFilters(state, action: { payload: { key: string; value: FilterValue } }) {
//       const { key, value } = action.payload;
//       const existingFilterIndex = state.items.findIndex(filter => filter.key === key);

//       if (existingFilterIndex !== -1) {
//         const existingFilterValueIndex = state.items[existingFilterIndex].value.findIndex(filter => filter === value);
//         if (existingFilterValueIndex === -1) {
//           state.items[existingFilterIndex].value.push(value);
//         } else {
//           // Update existing value based on your logic (optional)
//           // state.items[existingFilterIndex].value[existingFilterValueIndex] = value;
//         }
//       } else {
//         state.items.push({ key, value: [value] });
//       }
//     },
//     changeFilters(state, action: { payload: { key: string; value: FilterValue | FilterValue[] } }) {
//       const { key, value } = action.payload;

//       const searchKey = (currentArray: FilterItem[], currentKey: string) => {
//         const existingFilterIndex = currentArray.findIndex(filter => filter.key === currentKey);
//         if (existingFilterIndex !== -1) {
//           if (Array.isArray(value)) {
//             // Handle array of values (e.g., range filters)
//             state.items[existingFilterIndex].value = value;
//           } else if (typeof value === 'object' && !(value instanceof Array)) {
//             // Handle nested filters (optional)
//             searchKey(value as object, (value as object).key);
//           } else {
//             // Handle single value
//             state.items[existingFilterIndex].value ? state.items[existingFilterIndex].value.push(value) : state.items[existingFilterIndex].value = [value];
//           }
//         } else {
//           currentArray.push({ key, value: Array.isArray(value) ? value : [value] });
//         }
//       };

//       searchKey(state.items, key);
//     },
//     deleteFilters(state, action: { payload: { key: string; value?: FilterValue } }) {
//       const { key, value } = action.payload;

//       const searchKey = (currentArray: FilterItem[], currentKey: string) => {
//         const existingFilterIndex = currentArray.findIndex(filter => filter.key === currentKey);
//         if (existingFilterIndex !== -1) {
//           if (!value || value === "") {
//             currentArray.splice(existingFilterIndex, 1);
//           } else if (Array.isArray(value)) {
//             // Handle deleting specific values from an array
//             const filteredValues = state.items[existingFilterIndex].value.filter(filterValue => !value.includes(filterValue));
//             state.items[existingFilterIndex].value = filteredValues;
//           } else if (!(value instanceof Array)) {
//             const existingFilterValueIndex = currentArray[existingFilterIndex].value.findIndex(filter => filter === value);
//             if (existingFilterValueIndex !== -1 && currentArray[existingFilterIndex].value.length > 1) {
//               currentArray[existingFilterIndex].value.splice(existingFilterValueIndex, 1);
//             } else {
//               currentArray.splice(existingFilterIndex, 1);
//             }
//           }
//         }
//       };

//       searchKey(state.items, key);
//     },
//   },
// });

// export const { addFilters, changeFilters, deleteFilters } = filtersSlice.actions;
// export const filtersReducer = filtersSlice.reducer;
