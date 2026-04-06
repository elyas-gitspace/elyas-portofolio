import { render, screen } from '@testing-library/react';
import App from './App';

test('renders portfolio', () => {
  render(<App />);
  const badge = screen.getByText(/Recherche alternance/i);
  expect(badge).toBeInTheDocument();
});