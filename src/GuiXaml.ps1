# ============================================================================
#  BLOB OPTIMIZER - GuiXaml.ps1
#  WPF markup for the window interface. WPF ships with Windows / .NET, so
#  nothing is downloaded or installed. Pure ASCII: glyphs use XML entities.
# ============================================================================

# Shared theme: merged into the main window and every dialog.
$Blob.GuiTheme = @'
<ResourceDictionary xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
                    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
  <SolidColorBrush x:Key="Bg" Color="#000000"/>
  <SolidColorBrush x:Key="Panel" Color="#000000"/>
  <SolidColorBrush x:Key="Card" Color="#000000"/>
  <SolidColorBrush x:Key="CardHover" Color="#062A10"/>
  <SolidColorBrush x:Key="Line" Color="#0F6A24"/>
  <SolidColorBrush x:Key="Accent" Color="#3DFF6A"/>
  <SolidColorBrush x:Key="AccentDim" Color="#062A10"/>
  <SolidColorBrush x:Key="Text" Color="#3DFF6A"/>
  <SolidColorBrush x:Key="Sub" Color="#2EDB55"/>
  <SolidColorBrush x:Key="Muted" Color="#1E9A3E"/>
  <SolidColorBrush x:Key="Good" Color="#3DFF6A"/>
  <SolidColorBrush x:Key="Warn" Color="#3DFF6A"/>
  <SolidColorBrush x:Key="Bad" Color="#3DFF6A"/>

  <Style TargetType="TextBlock">
    <Setter Property="Foreground" Value="{StaticResource Text}"/>
    <Setter Property="FontFamily" Value="Consolas"/>
    <Setter Property="TextWrapping" Value="Wrap"/>
  </Style>

  <Style TargetType="Button">
    <Setter Property="Foreground" Value="{StaticResource Text}"/>
    <Setter Property="Background" Value="{StaticResource Card}"/>
    <Setter Property="BorderBrush" Value="{StaticResource Line}"/>
    <Setter Property="Padding" Value="14,7"/>
    <Setter Property="Margin" Value="0,0,8,0"/>
    <Setter Property="FontFamily" Value="Consolas"/>
    <Setter Property="FontSize" Value="13"/>
    <Setter Property="Cursor" Value="Hand"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="Button">
          <Border x:Name="Bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}"
                  BorderThickness="1" CornerRadius="0" Padding="{TemplateBinding Padding}">
            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
          </Border>
          <ControlTemplate.Triggers>
            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="BorderBrush" Value="{StaticResource Accent}"/></Trigger>
            <Trigger Property="IsPressed" Value="True"><Setter TargetName="Bd" Property="Background" Value="{StaticResource AccentDim}"/></Trigger>
            <Trigger Property="IsEnabled" Value="False"><Setter TargetName="Bd" Property="Opacity" Value="0.4"/></Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>
  <Style x:Key="AccentButton" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
    <Setter Property="Background" Value="{StaticResource Accent}"/>
    <Setter Property="BorderBrush" Value="{StaticResource Accent}"/>
    <Setter Property="Foreground" Value="#000000"/>
    <Setter Property="FontWeight" Value="SemiBold"/>
  </Style>
  <Style x:Key="DangerButton" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
    <Setter Property="Foreground" Value="{StaticResource Bad}"/>
    <Setter Property="BorderBrush" Value="#0F6A24"/>
  </Style>
  <Style x:Key="NavButton" TargetType="Button">
    <Setter Property="Foreground" Value="{StaticResource Sub}"/>
    <Setter Property="Background" Value="Transparent"/>
    <Setter Property="FontFamily" Value="Consolas"/>
    <Setter Property="FontSize" Value="14"/>
    <Setter Property="Cursor" Value="Hand"/>
    <Setter Property="HorizontalContentAlignment" Value="Left"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="Button">
          <Border x:Name="Bd" Background="{TemplateBinding Background}" CornerRadius="0" Margin="10,1" Padding="14,7">
            <ContentPresenter HorizontalAlignment="Left" VerticalAlignment="Center"/>
          </Border>
          <ControlTemplate.Triggers>
            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="#062A10"/></Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>
  <Style x:Key="TabButton" TargetType="Button">
    <Setter Property="Foreground" Value="{StaticResource Sub}"/>
    <Setter Property="Background" Value="Transparent"/>
    <Setter Property="BorderBrush" Value="Transparent"/>
    <Setter Property="FontFamily" Value="Consolas"/>
    <Setter Property="FontSize" Value="13.5"/>
    <Setter Property="Cursor" Value="Hand"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="Button">
          <Border x:Name="Bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}"
                  BorderThickness="0,0,0,2" Padding="14,0" Margin="2,0">
            <ContentPresenter VerticalAlignment="Center"/>
          </Border>
          <ControlTemplate.Triggers>
            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="#000000"/></Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>
  <Style x:Key="IconButton" TargetType="Button">
    <Setter Property="Foreground" Value="{StaticResource Sub}"/>
    <Setter Property="Background" Value="Transparent"/>
    <Setter Property="Width" Value="28"/>
    <Setter Property="Height" Value="28"/>
    <Setter Property="FontFamily" Value="Consolas"/>
    <Setter Property="FontSize" Value="13"/>
    <Setter Property="Cursor" Value="Hand"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="Button">
          <Border x:Name="Bd" Background="{TemplateBinding Background}" CornerRadius="0">
            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
          </Border>
          <ControlTemplate.Triggers>
            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="#062A10"/></Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>
  <Style x:Key="ChipButton" TargetType="Button">
    <Setter Property="Foreground" Value="{StaticResource Sub}"/>
    <Setter Property="Background" Value="#000000"/>
    <Setter Property="BorderBrush" Value="#0F6A24"/>
    <Setter Property="FontSize" Value="12.5"/>
    <Setter Property="Cursor" Value="Hand"/>
    <Setter Property="Margin" Value="0,0,8,8"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="Button">
          <Border x:Name="Bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="1"
                  CornerRadius="0" Padding="14,5">
            <ContentPresenter VerticalAlignment="Center"/>
          </Border>
          <ControlTemplate.Triggers>
            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="BorderBrush" Value="#3DFF6A"/></Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>
  <Style x:Key="Switch" TargetType="CheckBox">
    <Setter Property="Cursor" Value="Hand"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="CheckBox">
          <Border x:Name="Track" Width="44" Height="20" Background="#000000" BorderBrush="#0F6A24" BorderThickness="1">
            <Rectangle x:Name="Thumb" Width="16" Height="14" Fill="#1E9A3E" HorizontalAlignment="Left" Margin="2,0"/>
          </Border>
          <ControlTemplate.Triggers>
            <Trigger Property="IsChecked" Value="True">
              <Setter TargetName="Track" Property="BorderBrush" Value="#3DFF6A"/>
              <Setter TargetName="Thumb" Property="Fill" Value="#3DFF6A"/>
              <Setter TargetName="Thumb" Property="HorizontalAlignment" Value="Right"/>
            </Trigger>
            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Track" Property="BorderBrush" Value="#3DFF6A"/></Trigger>
            <Trigger Property="IsEnabled" Value="False"><Setter TargetName="Track" Property="Opacity" Value="0.35"/></Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>
  <Style x:Key="CaptionButton" TargetType="Button">
    <Setter Property="Foreground" Value="{StaticResource Sub}"/>
    <Setter Property="Background" Value="Transparent"/>
    <Setter Property="Width" Value="46"/>
    <Setter Property="FontFamily" Value="Consolas"/>
    <Setter Property="FontSize" Value="13"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="Button">
          <Border x:Name="Bd" Background="{TemplateBinding Background}">
            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
          </Border>
          <ControlTemplate.Triggers>
            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="#062A10"/></Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>

  <Style TargetType="CheckBox">
    <Setter Property="Foreground" Value="{StaticResource Text}"/>
    <Setter Property="Cursor" Value="Hand"/>
    <Setter Property="VerticalContentAlignment" Value="Top"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="CheckBox">
          <Grid Background="Transparent">
            <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
            <Border x:Name="Box" Width="18" Height="18" CornerRadius="0" Background="#000000" BorderBrush="#0F6A24"
                    BorderThickness="1.5" VerticalAlignment="Top" Margin="0,2,10,0">
              <Path x:Name="Mark" Data="M3,8 L7,12 L14,4" Stroke="#000000" StrokeThickness="2.2" Visibility="Collapsed"/>
            </Border>
            <ContentPresenter Grid.Column="1" VerticalAlignment="Top"/>
          </Grid>
          <ControlTemplate.Triggers>
            <Trigger Property="IsChecked" Value="True">
              <Setter TargetName="Box" Property="Background" Value="{StaticResource Accent}"/>
              <Setter TargetName="Box" Property="BorderBrush" Value="{StaticResource Accent}"/>
              <Setter TargetName="Mark" Property="Visibility" Value="Visible"/>
            </Trigger>
            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Box" Property="BorderBrush" Value="{StaticResource Accent}"/></Trigger>
            <Trigger Property="IsEnabled" Value="False"><Setter Property="Opacity" Value="0.45"/></Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>

  <Style TargetType="ScrollBar">
    <Setter Property="Width" Value="10"/>
    <Setter Property="MinWidth" Value="10"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="ScrollBar">
          <Track x:Name="PART_Track" IsDirectionReversed="True">
            <Track.Thumb><Thumb><Thumb.Template><ControlTemplate TargetType="Thumb">
              <Border CornerRadius="0" Background="#1E9A3E" Margin="2"/>
            </ControlTemplate></Thumb.Template></Thumb></Track.Thumb>
          </Track>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
    <Style.Triggers>
      <Trigger Property="Orientation" Value="Horizontal">
        <Setter Property="Width" Value="Auto"/>
        <Setter Property="Height" Value="10"/>
        <Setter Property="MinHeight" Value="10"/>
        <Setter Property="Template">
          <Setter.Value>
            <ControlTemplate TargetType="ScrollBar">
              <Track x:Name="PART_Track">
                <Track.Thumb><Thumb><Thumb.Template><ControlTemplate TargetType="Thumb">
                  <Border CornerRadius="0" Background="#1E9A3E" Margin="2"/>
                </ControlTemplate></Thumb.Template></Thumb></Track.Thumb>
              </Track>
            </ControlTemplate>
          </Setter.Value>
        </Setter>
      </Trigger>
    </Style.Triggers>
  </Style>

  <Style TargetType="TextBox">
    <Setter Property="Background" Value="#000000"/>
    <Setter Property="Foreground" Value="{StaticResource Text}"/>
    <Setter Property="BorderBrush" Value="#0F6A24"/>
    <Setter Property="CaretBrush" Value="{StaticResource Accent}"/>
    <Setter Property="Padding" Value="8,6"/>
    <Setter Property="FontSize" Value="13"/>
  </Style>

  <Style TargetType="ComboBox">
    <Setter Property="Foreground" Value="{StaticResource Text}"/>
    <Setter Property="FontSize" Value="13"/>
    <Setter Property="MinWidth" Value="180"/>
    <Setter Property="Height" Value="34"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="ComboBox">
          <Grid>
            <ToggleButton Focusable="False" ClickMode="Press"
                          IsChecked="{Binding IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}">
              <ToggleButton.Template>
                <ControlTemplate TargetType="ToggleButton">
                  <Border x:Name="Bd" Background="#000000" BorderBrush="#0F6A24" BorderThickness="1" CornerRadius="0">
                    <Path HorizontalAlignment="Right" VerticalAlignment="Center" Margin="0,0,12,0" Data="M0,0 L4,4 L8,0"
                          Stroke="#2EDB55" StrokeThickness="1.6"/>
                  </Border>
                  <ControlTemplate.Triggers>
                    <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="BorderBrush" Value="#3DFF6A"/></Trigger>
                  </ControlTemplate.Triggers>
                </ControlTemplate>
              </ToggleButton.Template>
            </ToggleButton>
            <ContentPresenter IsHitTestVisible="False" Margin="10,0,30,0" VerticalAlignment="Center"
                              Content="{TemplateBinding SelectionBoxItem}" ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}"/>
            <Popup IsOpen="{TemplateBinding IsDropDownOpen}" Placement="Bottom" AllowsTransparency="True" Focusable="False">
              <Border Background="#000000" BorderBrush="#0F6A24" BorderThickness="1" CornerRadius="0" Margin="0,2,0,0"
                      MinWidth="{TemplateBinding ActualWidth}" MaxHeight="320">
                <ScrollViewer><ItemsPresenter/></ScrollViewer>
              </Border>
            </Popup>
          </Grid>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>
  <Style TargetType="ComboBoxItem">
    <Setter Property="Foreground" Value="{StaticResource Text}"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="ComboBoxItem">
          <Border x:Name="Bd" Padding="10,6" Background="Transparent"><ContentPresenter/></Border>
          <ControlTemplate.Triggers>
            <Trigger Property="IsHighlighted" Value="True"><Setter TargetName="Bd" Property="Background" Value="#062A10"/></Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>

  <Style TargetType="ListBox">
    <Setter Property="Background" Value="Transparent"/>
    <Setter Property="BorderThickness" Value="0"/>
    <Setter Property="Foreground" Value="{StaticResource Text}"/>
  </Style>
  <Style TargetType="ListBoxItem">
    <Setter Property="Foreground" Value="{StaticResource Text}"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="ListBoxItem">
          <Border x:Name="Bd" Padding="12,8" Margin="0,1" CornerRadius="0" Background="{StaticResource Card}" BorderBrush="Transparent" BorderThickness="1">
            <ContentPresenter/>
          </Border>
          <ControlTemplate.Triggers>
            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="{StaticResource CardHover}"/></Trigger>
            <Trigger Property="IsSelected" Value="True"><Setter TargetName="Bd" Property="BorderBrush" Value="{StaticResource Accent}"/></Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>

  <Style TargetType="DataGrid">
    <Setter Property="Background" Value="{StaticResource Panel}"/>
    <Setter Property="Foreground" Value="{StaticResource Text}"/>
    <Setter Property="BorderBrush" Value="{StaticResource Line}"/>
    <Setter Property="RowBackground" Value="Transparent"/>
    <Setter Property="AlternatingRowBackground" Value="#000000"/>
    <Setter Property="GridLinesVisibility" Value="None"/>
    <Setter Property="HeadersVisibility" Value="Column"/>
    <Setter Property="AutoGenerateColumns" Value="False"/>
    <Setter Property="IsReadOnly" Value="True"/>
    <Setter Property="CanUserAddRows" Value="False"/>
    <Setter Property="SelectionMode" Value="Extended"/>
    <Setter Property="SelectionUnit" Value="FullRow"/>
    <Setter Property="RowHeight" Value="30"/>
    <Setter Property="FontSize" Value="13"/>
  </Style>
  <Style TargetType="DataGridColumnHeader">
    <Setter Property="Background" Value="#000000"/>
    <Setter Property="Foreground" Value="{StaticResource Sub}"/>
    <Setter Property="Padding" Value="10,7"/>
    <Setter Property="BorderBrush" Value="{StaticResource Line}"/>
    <Setter Property="BorderThickness" Value="0,0,0,1"/>
    <Setter Property="FontWeight" Value="SemiBold"/>
  </Style>
  <Style TargetType="DataGridCell">
    <Setter Property="BorderThickness" Value="0"/>
    <Setter Property="Padding" Value="10,0"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="DataGridCell">
          <Border Background="{TemplateBinding Background}" Padding="{TemplateBinding Padding}">
            <ContentPresenter VerticalAlignment="Center"/>
          </Border>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
    <Style.Triggers>
      <Trigger Property="IsSelected" Value="True">
        <Setter Property="Background" Value="#062A10"/>
        <Setter Property="Foreground" Value="White"/>
      </Trigger>
    </Style.Triggers>
  </Style>

  <Style TargetType="ProgressBar">
    <Setter Property="Height" Value="8"/>
    <Setter Property="Foreground" Value="{StaticResource Accent}"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="ProgressBar">
          <Grid>
            <Border x:Name="PART_Track" Background="#062A10" CornerRadius="0"/>
            <Border x:Name="PART_Indicator" HorizontalAlignment="Left" Background="{TemplateBinding Foreground}" CornerRadius="0"/>
          </Grid>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>

  <Style TargetType="ToolTip">
    <Setter Property="Foreground" Value="{StaticResource Text}"/>
    <Setter Property="HasDropShadow" Value="False"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="ToolTip">
          <Border Background="#000000" BorderBrush="#0F6A24" BorderThickness="1" CornerRadius="0" Padding="14,12" MaxWidth="520">
            <ContentPresenter/>
          </Border>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>
</ResourceDictionary>
'@

$Blob.GuiXaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="BLOB OPTIMIZER" Width="1240" Height="820" MinWidth="980" MinHeight="620"
        WindowStartupLocation="CenterScreen" Background="#000000" WindowStyle="None" ResizeMode="CanResize"
        FontFamily="Consolas" UseLayoutRounding="True" TextOptions.TextFormattingMode="Display">
  <WindowChrome.WindowChrome>
    <WindowChrome CaptionHeight="46" ResizeBorderThickness="6" GlassFrameThickness="0" CornerRadius="0"/>
  </WindowChrome.WindowChrome>
  <!--THEME-->
  <Border x:Name="RootBorder" BorderBrush="#0F6A24" BorderThickness="1">
    <Grid>
      <Grid.RowDefinitions>
        <RowDefinition Height="46"/>
        <RowDefinition Height="44"/>
        <RowDefinition Height="*"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="28"/>
      </Grid.RowDefinitions>

      <!-- Title bar -->
      <Grid Grid.Row="0" Background="#000000">
        <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="18,0,0,0">
          <TextBlock Text="&gt;_" FontWeight="Bold" FontSize="15" Foreground="#3DFF6A" Margin="0,0,10,0" VerticalAlignment="Center"/>
          <TextBlock Text="BLOB" FontWeight="Bold" FontSize="15" Foreground="#3DFF6A" VerticalAlignment="Center"/>
          <TextBlock Text=" OPTIMIZER" FontWeight="SemiBold" FontSize="15" VerticalAlignment="Center"/>
          <TextBlock x:Name="TitleVersion" Foreground="#1E9A3E" FontSize="12" Margin="10,0,0,0" VerticalAlignment="Center"/>
          <Border x:Name="AdminBadge" CornerRadius="0" Padding="8,2" Margin="14,0,0,0" VerticalAlignment="Center">
            <TextBlock x:Name="AdminBadgeText" FontSize="11" FontWeight="SemiBold"/>
          </Border>
          <Border x:Name="DryRunBadge" CornerRadius="0" Padding="8,2" Margin="8,0,0,0" Background="#062A10" VerticalAlignment="Center" Visibility="Collapsed">
            <TextBlock Text="DRY RUN" FontSize="11" FontWeight="SemiBold" Foreground="#3DFF6A"/>
          </Border>
        </StackPanel>
        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
          <Button x:Name="BtnMin" Style="{StaticResource CaptionButton}" Content="_" WindowChrome.IsHitTestVisibleInChrome="True" ToolTip="Minimize"/>
          <Button x:Name="BtnMax" Style="{StaticResource CaptionButton}" Content="[ ]" WindowChrome.IsHitTestVisibleInChrome="True" ToolTip="Maximize"/>
          <Button x:Name="BtnClose" Style="{StaticResource CaptionButton}" Content="X" WindowChrome.IsHitTestVisibleInChrome="True" ToolTip="Close"/>
        </StackPanel>
      </Grid>

      <!-- Tab bar -->
      <Border Grid.Row="1" Background="#000000" BorderBrush="#0F6A24" BorderThickness="0,1,0,1">
        <ScrollViewer HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Disabled" Margin="10,0">
          <StackPanel x:Name="NavPanel" Orientation="Horizontal"/>
        </ScrollViewer>
      </Border>

      <!-- Page -->
      <Grid Grid.Row="2" Background="#000000">
        <Grid.RowDefinitions>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        <Border Grid.Row="0" Padding="30,18,24,8">
          <DockPanel>
            <StackPanel x:Name="PageActions" DockPanel.Dock="Right" Orientation="Horizontal" VerticalAlignment="Center"/>
            <StackPanel>
              <TextBlock x:Name="PageTitle" FontSize="24" FontWeight="SemiBold"/>
              <TextBlock x:Name="PageSubtitle" FontSize="13" Foreground="#2EDB55" Margin="0,4,0,0"/>
            </StackPanel>
          </DockPanel>
        </Border>
        <ScrollViewer x:Name="PageScroll" Grid.Row="1" VerticalScrollBarVisibility="Auto" Padding="30,12,24,24">
          <ContentControl x:Name="PageHost"/>
        </ScrollViewer>
      </Grid>

      <!-- Activity log -->
      <Border Grid.Row="3" Background="#000000" BorderBrush="#0F6A24" BorderThickness="0,1,0,0">
        <DockPanel>
          <DockPanel DockPanel.Dock="Top" Margin="18,6,12,2">
            <Button x:Name="BtnToggleLog" DockPanel.Dock="Right" Content="Hide" Padding="10,3" Margin="0" FontSize="11"/>
            <Button x:Name="BtnClearLog" DockPanel.Dock="Right" Content="Clear" Padding="10,3" FontSize="11"/>
            <TextBlock Text="ACTIVITY" FontSize="11" FontWeight="Bold" Foreground="#1E9A3E" VerticalAlignment="Center"/>
          </DockPanel>
          <ScrollViewer x:Name="LogScroll" Height="86" VerticalScrollBarVisibility="Auto" Padding="18,0,12,6">
            <StackPanel x:Name="LogPanel"/>
          </ScrollViewer>
        </DockPanel>
      </Border>

      <!-- Status bar -->
      <Border Grid.Row="4" Background="#000000" BorderBrush="#0F6A24" BorderThickness="0,1,0,0">
        <DockPanel Margin="18,0">
          <TextBlock x:Name="StatusRight" DockPanel.Dock="Right" Foreground="#1E9A3E" FontSize="11" VerticalAlignment="Center"/>
          <TextBlock x:Name="StatusText" Foreground="#2EDB55" FontSize="11" VerticalAlignment="Center" Text="Ready"/>
        </DockPanel>
      </Border>
    </Grid>
  </Border>
</Window>
'@

$Blob.GuiDialogXaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Width="720" Height="560" MinWidth="520" MinHeight="320" WindowStyle="None" ResizeMode="CanResize"
        WindowStartupLocation="CenterOwner" Background="#000000" ShowInTaskbar="False" FontFamily="Consolas">
  <WindowChrome.WindowChrome>
    <WindowChrome CaptionHeight="56" ResizeBorderThickness="6" GlassFrameThickness="0" CornerRadius="0"/>
  </WindowChrome.WindowChrome>
  <!--THEME-->
  <Border x:Name="DlgBorder" BorderBrush="#3DFF6A" BorderThickness="1">
    <DockPanel>
      <Border DockPanel.Dock="Top" Padding="24,16,24,12" BorderBrush="#0F6A24" BorderThickness="0,0,0,1">
        <StackPanel>
          <TextBlock x:Name="DlgTitle" FontSize="18" FontWeight="SemiBold"/>
          <TextBlock x:Name="DlgSub" FontSize="12" Foreground="#2EDB55" Margin="0,4,0,0"/>
        </StackPanel>
      </Border>
      <Border DockPanel.Dock="Bottom" Padding="24,12" BorderBrush="#0F6A24" BorderThickness="0,1,0,0" Background="#000000">
        <DockPanel>
          <StackPanel DockPanel.Dock="Right" Orientation="Horizontal">
            <Button x:Name="DlgCancel" Content="Cancel" MinWidth="96"/>
            <Button x:Name="DlgOk" Content="Confirm" MinWidth="120" Margin="0" Style="{StaticResource AccentButton}"/>
          </StackPanel>
          <CheckBox x:Name="DlgCheck" VerticalAlignment="Center" Margin="0,0,16,0" Visibility="Collapsed">
            <TextBlock x:Name="DlgCheckText" FontSize="13"/>
          </CheckBox>
        </DockPanel>
      </Border>
      <ScrollViewer VerticalScrollBarVisibility="Auto" Padding="24,14">
        <StackPanel x:Name="DlgBody"/>
      </ScrollViewer>
    </DockPanel>
  </Border>
</Window>
'@
