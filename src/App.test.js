import { render, screen } from '@testing-library/react';
import App from './App';

test('renders welcome message', () => {
  render(<App />);
  const linkElement = screen.getByText(/Hello, DevOps Engineer!/i);
  expect(linkElement).toBeInTheDocument();
});
