// @vitest-environment jsdom
import { describe, it, expect } from 'vitest';
import '@testing-library/jest-dom';
import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import { PropertyGrid } from '../property-grid';

describe('PropertyGrid Geographic Reference Frame Inputs', () => {
  const getFieldInput = (labelText: string) => {
    const label = screen.getByText(labelText);
    return label.nextElementSibling as HTMLInputElement;
  };

  it('should render all 5 new inputs correctly with initial values', () => {
    const { container } = render(<PropertyGrid activeView="Location" />);

    const astroInput = getFieldInput('Astronomical Body');
    const datumInput = getFieldInput('Geodetic Datum');
    const coordAccInput = getFieldInput('Coordinate Accuracy');
    const heightAccInput = getFieldInput('Height Accuracy');
    const alternateInput = getFieldInput('Alternate System');

    expect(astroInput).toBeInTheDocument();
    expect(astroInput.value).toBe('earth');

    expect(datumInput).toBeInTheDocument();
    expect(datumInput.value).toBe('wgs-84');

    expect(coordAccInput).toBeInTheDocument();
    expect(coordAccInput.value).toBe('0.001');

    expect(heightAccInput).toBeInTheDocument();
    expect(heightAccInput.value).toBe('0.001');

    expect(alternateInput).toBeInTheDocument();
    expect(alternateInput.value).toBe('');

    // Pre element should contain initial committed values
    const pre = container.querySelector('pre');
    expect(pre?.textContent).toContain('"astronomicalBody": "earth"');
    expect(pre?.textContent).toContain('"geodeticDatum": "wgs-84"');
    expect(pre?.textContent).toContain('"coordAccuracy": 0.001');
    expect(pre?.textContent).toContain('"heightAccuracy": 0.001');
    expect(pre?.textContent).toContain('"alternateSystem": ""');
  });

  it('should buffer input changes locally and not update pre text until blur', () => {
    const { container } = render(<PropertyGrid activeView="Location" />);
    const astroInput = getFieldInput('Astronomical Body');

    // Change input value
    fireEvent.change(astroInput, { target: { value: 'mars' } });

    // Local buffer should be updated
    expect(astroInput.value).toBe('mars');

    // Pre text should still have the original committed value 'earth'
    const pre = container.querySelector('pre');
    expect(pre?.textContent).toContain('"astronomicalBody": "earth"');

    // Trigger blur
    fireEvent.blur(astroInput);

    // Pre text should now be updated to 'mars'
    expect(pre?.textContent).toContain('"astronomicalBody": "mars"');
  });

  it('should validate astronomicalBody on blur: invalid values display error text, apply input-error class, and prevent save', () => {
    const { container } = render(<PropertyGrid activeView="Location" />);
    const astroInput = getFieldInput('Astronomical Body');

    // 'Earth' is invalid (contains uppercase)
    fireEvent.change(astroInput, { target: { value: 'Earth' } });
    fireEvent.blur(astroInput);

    expect(screen.getByText('Must contain only ASCII, lowercase, and no leading "the "')).toBeInTheDocument();
    expect(astroInput).toHaveClass('input-error');

    // Pre text should still have the original committed value 'earth'
    const pre = container.querySelector('pre');
    expect(pre?.textContent).toContain('"astronomicalBody": "earth"');

    // 'the mars' is invalid (starts with "the ")
    fireEvent.change(astroInput, { target: { value: 'the mars' } });
    fireEvent.blur(astroInput);

    expect(screen.getByText('Must contain only ASCII, lowercase, and no leading "the "')).toBeInTheDocument();
    expect(astroInput).toHaveClass('input-error');
    expect(pre?.textContent).toContain('"astronomicalBody": "earth"');

    // Correct value should clear error and commit
    fireEvent.change(astroInput, { target: { value: 'mars' } });
    fireEvent.blur(astroInput);

    expect(screen.queryByText('Must contain only ASCII, lowercase, and no leading "the "')).not.toBeInTheDocument();
    expect(astroInput).not.toHaveClass('input-error');
    expect(pre?.textContent).toContain('"astronomicalBody": "mars"');
  });

  it('should validate geodeticDatum on blur: invalid values display error, apply input-error class, and prevent save', () => {
    const { container } = render(<PropertyGrid activeView="Location" />);
    const datumInput = getFieldInput('Geodetic Datum');

    // 'wgs 84' is invalid (contains space)
    fireEvent.change(datumInput, { target: { value: 'wgs 84' } });
    fireEvent.blur(datumInput);

    expect(screen.getByText('Must contain only ASCII, lowercase, and no spaces')).toBeInTheDocument();
    expect(datumInput).toHaveClass('input-error');

    const pre = container.querySelector('pre');
    expect(pre?.textContent).toContain('"geodeticDatum": "wgs-84"');

    // Correct value should clear error and commit
    fireEvent.change(datumInput, { target: { value: 'wgs84' } });
    fireEvent.blur(datumInput);

    expect(screen.queryByText('Must contain only ASCII, lowercase, and no spaces')).not.toBeInTheDocument();
    expect(datumInput).not.toHaveClass('input-error');
    expect(pre?.textContent).toContain('"geodeticDatum": "wgs84"');
  });

  it('should validate coordAccuracy on blur: invalid values display error, apply input-error class, and prevent save', () => {
    const { container } = render(<PropertyGrid activeView="Location" />);
    const coordAccInput = getFieldInput('Coordinate Accuracy');

    // -1.2 is invalid (negative)
    fireEvent.change(coordAccInput, { target: { value: '-1.2' } });
    fireEvent.blur(coordAccInput);

    expect(screen.getByText('Must be non-negative and have up to 6 decimal places')).toBeInTheDocument();
    expect(coordAccInput).toHaveClass('input-error');

    const pre = container.querySelector('pre');
    expect(pre?.textContent).toContain('"coordAccuracy": 0.001');

    // 0.1234567 is invalid (7 decimal places)
    fireEvent.change(coordAccInput, { target: { value: '0.1234567' } });
    fireEvent.blur(coordAccInput);

    expect(screen.getByText('Must be non-negative and have up to 6 decimal places')).toBeInTheDocument();
    expect(coordAccInput).toHaveClass('input-error');
    expect(pre?.textContent).toContain('"coordAccuracy": 0.001');

    // Correct value should clear error and commit as number
    fireEvent.change(coordAccInput, { target: { value: '0.123' } });
    fireEvent.blur(coordAccInput);

    expect(screen.queryByText('Must be non-negative and have up to 6 decimal places')).not.toBeInTheDocument();
    expect(coordAccInput).not.toHaveClass('input-error');
    expect(pre?.textContent).toContain('"coordAccuracy": 0.123');
  });

  it('should validate heightAccuracy on blur: invalid values display error, apply input-error class, and prevent save', () => {
    const { container } = render(<PropertyGrid activeView="Location" />);
    const heightAccInput = getFieldInput('Height Accuracy');

    // -0.5 is invalid (negative)
    fireEvent.change(heightAccInput, { target: { value: '-0.5' } });
    fireEvent.blur(heightAccInput);

    expect(screen.getByText('Must be non-negative and have up to 6 decimal places')).toBeInTheDocument();
    expect(heightAccInput).toHaveClass('input-error');

    const pre = container.querySelector('pre');
    expect(pre?.textContent).toContain('"heightAccuracy": 0.001');

    // Correct value should clear error and commit as number
    fireEvent.change(heightAccInput, { target: { value: '0.5' } });
    fireEvent.blur(heightAccInput);

    expect(screen.queryByText('Must be non-negative and have up to 6 decimal places')).not.toBeInTheDocument();
    expect(heightAccInput).not.toHaveClass('input-error');
    expect(pre?.textContent).toContain('"heightAccuracy": 0.5');
  });
});
