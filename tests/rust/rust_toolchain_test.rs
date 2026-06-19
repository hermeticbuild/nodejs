#[test]
fn compiles_and_runs_with_the_registered_toolchain() {
    let values = [20_u32, 26, 36];
    assert_eq!(values.into_iter().sum::<u32>(), 82);
}
