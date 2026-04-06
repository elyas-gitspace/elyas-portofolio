import { render, screen } from '@testing-library/react';
import App from './App';

test('renders portfolio', () => {
  render(<App />);
  const name = screen.getByText(/MEZIANI/i);
  expect(name).toBeInTheDocument();
});