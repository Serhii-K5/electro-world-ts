import styled, { css } from "styled-components";
import { transition } from "../ConstComponentsStyle/ConstComponentsStyle.styled";

interface SpanProps {
  color?: "black" | "blue";
}

export const VodafoneBg = styled.div`
  display: inline-flex;
  border-radius: 50%;
  background-color: var(--primary-white);
`;

export const Span =
  styled.span <SpanProps>
  `
  font-size: 16px;
  width: 162px;
  transition: font-size ${transition}, color ${transition};

  ${(props) =>
    props.color === "black" &&
    css`
      color: var(--primary-black);

      &.isScaleKs,
      &.isScaleVd {
        color: red;
      }
    `}

  ${(props) =>
    props.color === "blue" &&
    css`
      color: var(--active-blue);

      &.isScaleKs,
      &.isScaleVd {
        color: red;
      }
    `}
`;
