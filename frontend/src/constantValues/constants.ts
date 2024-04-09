export const STORE_NAME: string = "Electro world";
export const SHIFT_RANGE: number = 20;
export const FILTER_PANEL_WIDTH: string = "300px - 70px"; // (width asade in catalog page) - (shift right)
export const PHONE_KS: string = "+380689766880";
export const PHONE_KS_STR: string = "+38(068)976-68-80";
export const PHONE_MTC: string = "+380689766880";
export const PHONE_MTC_STR: string = "+38(068)976-68-80";
export interface Product {
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

